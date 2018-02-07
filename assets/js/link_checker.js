'use strict';

let nbPagesChecked; // number of pages checked so far
let nbLinks; // total number of links
let pageIndex; // current page index
let linkIndex; // current link index in the page
let linkCount; // number of links checked so far
let nbBroken; // number of issues found
let pages; // array returned by extractor.cfc / extractLinks
let stopRequested; // boolean, true if a stop was requested
let timeout; // integer, user-defined timeout in s
let maxBatch; // number of URLs checked at once on the server
let ignoreRedirects; // boolean, true if the user chose to ignore redirects
let currentPageURL; // string, current page URL
let currentPageTD; // Element, current page td element in the result table
let allResults; // array with all the results found so far (used to avoid querying the same URL twice)

let init = function() {
    maxBatch = 10;
    timeout = 3; // default timeout in s
    let timeoutInput = document.getElementById('timeout');
    timeoutInput.value = timeout;
    let startButton = document.getElementById('startChecking');
    startButton.addEventListener('click', (e) => startChecking(), false);

    let stopButton = document.getElementById('stopChecking');
    stopButton.disabled = true;
    stopButton.addEventListener('click', (e) => stopChecking(), false);
}

let startChecking = function() {
    let extractingP = document.getElementById('extracting');
    extractingP.style.display = '';
    let startButton = document.getElementById('startChecking');
    startButton.disabled = true;
    stopRequested = false;
    let stopButton = document.getElementById('stopChecking');
    stopButton.disabled = false;
    let brokenLinksTableBody = document.getElementById('brokenLinksTableBody');
    brokenLinksTableBody.innerHTML = '';
    nbPagesChecked = 0;
    nbLinks = 0;
    pageIndex = 0;
    linkIndex = 0;
    linkCount = 0;
    nbBroken = 0;
    pages = [];
    allResults = [];
    currentPageURL = null;
    currentPageTD = null;
    let timeoutInput = document.getElementById('timeout');
    timeoutInput.setAttribute('readonly', 'readonly');
    timeout = parseInt(timeoutInput.value);
    let ignoreRedirectsCheckbox = document.getElementById('ignoreRedirects');
    ignoreRedirects = ignoreRedirectsCheckbox.checked;
    let nbPagesCheckedSpan = document.getElementById('nbPagesChecked');
    nbPagesCheckedSpan.innerHTML = '' + pageIndex;
    let nbPagesSpan = document.getElementById('nbPages');
    nbPagesSpan.innerHTML = '0';
    let nbLinksCheckedSpan = document.getElementById('nbLinksChecked');
    nbLinksCheckedSpan.innerHTML = '' + linkCount;
    let nbLinksSpan = document.getElementById('nbLinks');
    nbLinksSpan.innerHTML = '' + nbLinks;
    nbBroken = 0;
    let nbBrokenSpan = document.getElementById('nbBroken');
    nbBrokenSpan.innerHTML = '' + nbBroken;
    udpateProgressBar();

    request(muraLinkCheckerPath, {action: 'extract_links'}, (response) => {
        extractingP.style.display = 'none';
        pages = JSON.parse(response);
        checkLinks();
    }, (error) => {
        extractingP.style.display = 'none';
        console.log(error);
    });
}

let stopChecking = function() {
    stopRequested = true;
    let stopButton = document.getElementById('stopChecking');
    stopButton.disabled = true;
}

let endChecking = function() {
    let startButton = document.getElementById('startChecking');
    startButton.disabled = false;
    let stopButton = document.getElementById('stopChecking');
    stopButton.disabled = true;
    let timeoutInput = document.getElementById('timeout');
    timeoutInput.removeAttribute('readonly');
}

let checkLinks = function() {
    // Each page object has url and links. Each link has element and url.
    let nbPages = pages.length;
    let nbPagesSpan = document.getElementById('nbPages');
    nbPagesSpan.innerHTML = '' + nbPages;
    nbLinks = 0;
    for (let page of pages)
        nbLinks += page.links.length;
    let nbLinksSpan = document.getElementById('nbLinks');
    nbLinksSpan.innerHTML = '' + nbLinks;
    linkIndex = 0;
    startNextCheck(pages);
}

let startNextCheck = function() {
    let urls = [];
    let urlInfos = [];
    let oldResults = [];
    while (urls.length < maxBatch && pageIndex < pages.length) {
        let page = pages[pageIndex];
        while (urls.length < maxBatch && linkIndex < page.links.length) {
            let url = page.links[linkIndex].url;
            if (!/^\/|^[a-zA-Z]+:\/\//.test(url))
                url = page.url + url; // link relative to the page
            urlInfos.push({
                url: url,
                element: page.links[linkIndex].element,
                page: page.url
            });
            if (urls.indexOf(url) == -1) {
                // see if we had already checked the URL; if so, don't do another request for it
                let found = false;
                for (let i=0; i<allResults.length; i++) {
                    if (allResults[i].url == url) {
                        found = true;
                        oldResults.push(allResults[i]);
                        break;
                    }
                }
                if (!found)
                    urls.push(url);
            }
            linkIndex++;
            linkCount++;
        }
        if (linkIndex == page.links.length) {
            pageIndex++;
            linkIndex = 0;
        }
    }
    let params = {
        action: 'check_links',
        urls: urls,
        timeout: timeout,
        followRedirects: ignoreRedirects
    }
    request(muraLinkCheckerPath, params, (response) => {
        let results = JSON.parse(response);
        continueNextCheck(urlInfos, results, oldResults);
    }, (error) => {
        console.log(error);
    });
}

let continueNextCheck = function(urlInfos, results, oldResults) {
    let nbPagesCheckedSpan = document.getElementById('nbPagesChecked');
    nbPagesCheckedSpan.innerHTML = '' + pageIndex;
    let nbLinksCheckedSpan = document.getElementById('nbLinksChecked');
    nbLinksCheckedSpan.innerHTML = '' + linkCount;
    allResults = allResults.concat(results);
    results = results.concat(oldResults);
    for (let result of results) {
        if (result.status != '200' &&
                (!ignoreRedirects || result.status == null || !/^3[0-9][0-9]/.test(result.status))) {
            nbBroken++;
            let infos = null;
            for (let inf of urlInfos) {
                if (inf.url == result.url) {
                    infos = inf;
                    break;
                }
            }
            if (infos != null) {
                let tbody = document.getElementById('brokenLinksTableBody');
                let tr = document.createElement('tr');
                let td;
                if (infos.page != currentPageURL) {
                    td = document.createElement('td');
                    let pageLink = document.createElement('a');
                    let pageURL = infos.page;
                    if (pageURL.startsWith('/'))
                        pageURL = muraLinkCheckerSiteURL + pageURL;
                    pageLink.setAttribute('href', pageURL);
                    pageLink.setAttribute('target', 'brokenLink');
                    pageLink.appendChild(document.createTextNode(infos.page));
                    td.appendChild(pageLink);
                    tr.appendChild(td);
                    currentPageTD = td;
                } else {
                    let rows = currentPageTD.getAttribute('rowspan');
                    if (rows == null)
                        rows = 1;
                    else
                        rows = parseInt(rows);
                    currentPageTD.setAttribute('rowspan', rows + 1);
                }
                td = document.createElement('td');
                let resCode = document.createElement('code');
                resCode.appendChild(document.createTextNode(result.status));
                td.appendChild(resCode);
                tr.appendChild(td);
                td = document.createElement('td');
                let elementCode = document.createElement('code');
                elementCode.appendChild(document.createTextNode(infos.element));
                td.appendChild(elementCode);
                tr.appendChild(td);
                td = document.createElement('td');
                if (infos.url.startsWith('/') || infos.url.startsWith('http')) {
                    let docLink = document.createElement('a');
                    let linkurl = infos.url;
                    if (linkurl.startsWith('/'))
                        linkurl = muraLinkCheckerSiteURL + linkurl;
                    docLink.setAttribute('href', linkurl);
                    docLink.setAttribute('target', 'brokenLink');
                    docLink.appendChild(document.createTextNode(infos.url));
                    td.appendChild(docLink);
                } else {
                    td.appendChild(document.createTextNode(infos.url));
                }
                tr.appendChild(td);
                tbody.appendChild(tr);
                currentPageURL = infos.page;
            }
        }
    }
    let nbBrokenSpan = document.getElementById('nbBroken');
    nbBrokenSpan.innerHTML = '' + nbBroken;
    udpateProgressBar();
    if (stopRequested || pageIndex == pages.length)
        endChecking();
    else
        startNextCheck();
}

let udpateProgressBar = function() {
    let progressBar = document.getElementById('progressBar');
    let percent;
    if (nbLinks == 0)
        percent = '0';
    else
        percent = '' + Math.round(100 * linkCount / nbLinks);
    progressBar.setAttribute('aria-valuenow', percent);
    progressBar.style.width = percent + '%';
    let srProgress = document.getElementById('srProgress');
    srProgress.firstChild.nodeValue = percent + "% Complete";
}

let request = function(url, parameters, resolve, reject) {
    let req = new XMLHttpRequest();
    req.open('POST', url);
    req.onload = (e) => {
        if (req.status === 200) {
            resolve(req.response);
        } else {
            reject(new Error(req.statusText));
        }
    };
    req.onerror = () => {
        console.log("Error for POST request at " + url);
        reject(new Error("Network error"));
    };
    let formData = new FormData();
    for (let key in parameters) {
        if (typeof parameters[key] === 'object')
            formData.append(key, JSON.stringify(parameters[key]));
        else
            formData.append(key, parameters[key]);
    }
    req.send(formData);
}

init();
