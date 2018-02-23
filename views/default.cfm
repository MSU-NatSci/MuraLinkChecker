
<cfsavecontent variable="head"><cfoutput>
    <cfset pluginspath = $.siteConfig().getPluginsPath()>
    <link href="#pluginspath#/#settings.package#/assets/css/link_checker.css" rel="stylesheet">
    <script>
        muraLinkCheckerPath = "#pluginspath#/#settings.package#/";
        muraLinkCheckerSiteURL = "#$.siteConfig().getWebPath(complete=1)#";
    </script>
    <script src="#pluginspath#/#settings.package#/assets/js/link_checker.js" defer></script>
</cfoutput></cfsavecontent>
<cfhtmlhead text='#head#'>

<cfsavecontent variable="body"><cfoutput>
    <div class="mura-header">
        <h1>#HTMLEditFormat(pluginConfig.getName())#</h1>
        <div class="nav-module-specific btn-group">
            <cfset moduleid = pluginConfig.getValue('moduleid')>
            <a class="btn" title="Plugin Permissions" href="#$.globalConfig('context')#/admin/?muraAction=cPerm.module&amp;contentid=#moduleid#&amp;siteid=#session.siteid#&amp;moduleid=#moduleid#">
                <i class="mi-key"></i> Plugin Permissions
            </a>
        </div>
    </div>
    <div class="block block-constrain">
        <div class="block block-bordered">
            <div class="block-content">
                <cfset configBean = $.getBean('configBean')>
                <p>
                    <button id="startChecking" class="btn">Start checking the site</button>
                    <button id="stopChecking" class="btn">Stop</button>
                </p>
                <p>
                    <label for="timeout">Timeout:</label> <input id="timeout" type="text" size="4">s
                    &nbsp;
                    <input id="ignoreRedirects" type="checkbox" value="ignore">
                    <label for="ignoreRedirects">Ignore redirects</label>
                </p>
                <p id="extracting" style="display:none">Extracting links from the site...</p>
                <div class="progress">
                    <div id="progressBar" class="progress-bar" role="progressbar" aria-valuenow="0"
                    aria-valuemin="0" aria-valuemax="100" style="width:0%">
                        <span id="srProgress" class="sr-only">0% Complete</span>
                    </div>
                </div>
                <p><strong>Number of pages checked:</strong> <span id="nbPagesChecked">0</span>/<span id="nbPages">0</span></p>
                <p><strong>Number of links checked:</strong> <span id="nbLinksChecked">0</span>/<span id="nbLinks">0</span></p>
                <p><strong>Total number of links with issues:</strong> <span id="nbBroken">0</span></p>
                <table id="brokenLinksTable">
                    <caption>Broken or Redirected Links</caption>
                    <thead>
                        <tr><th>Page</th><th>Status</th><th>HTML element</th><th>Link</th></tr>
                    </thead>
                    <tbody id="brokenLinksTableBody">
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</cfoutput></cfsavecontent>
<cfoutput>
    #$.getBean('pluginManager').renderAdminTemplate(body=body, pagetitle=pluginConfig.getName())#
</cfoutput>
