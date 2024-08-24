function screenshot(url, save_name) {
    var page = require('webpage').create();
    page.viewportSize = {width: 1280, height: 1024};

    page.onAlert = page.onPrompt = page.onConfirm = page.onError = function () {
    };

    page.settings.userAgent = 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.116 Safari/537.36';
    page.settings.resourceTimeout = 1000*15;


    var cnt = 0;
    page.onNavigationRequested = function (url2, type, willNavigate, main) {
        cnt += 1;
        if (main && url2 !== url && cnt < 7) {
            page.close();

            setTimeout(function () {
                screenshot(url2, save_name)
            }, 100);
        }
    };


    page.open(url, function (status) {
        //console.debug(status);
        if (status === "success") {
            return window.setTimeout(pageRender, 2000);
        } else {
            return window.setTimeout(pageRender, 2000);
        }
    });


    window.setTimeout(pageRender, 60*1.2*1000);
    function pageRender() {
        page.evaluate(function () {
            document.body.bgColor = 'white';
        });

        page.clipRect = {
            top: 0,
            left: 0,
            width: 1280,
            height: 1024
        };

        page.render(save_name, {format: 'jpeg', quality: '100'});
        phantom.exit(0);
    }

}


function main() {

    var system = require('system');
    var p_url = new RegExp('-u=(.*)');
    var p_save_name = new RegExp('-s=(.*)');
    for (var i = 0; i < system.args.length; i++) {
        if (p_url.test(system.args[i]) === true) {
            var url = p_url.exec(system.args[i])[1];
        }

        if (p_save_name.test(system.args[i]) === true) {
            var save_name = p_save_name.exec(system.args[i])[1];
        }

    }

    if (typeof(url) === 'undefined' || url.length == 0 || typeof(save_name) === 'undefined' || save_name.length == 0) {
        console.log("Usage: phantomjs screenshot.js -u=http://swww.baidu.com/ -s=baidu.jpg ");

        phantom.exit(1);
    }

    screenshot(url, save_name)
}

main();