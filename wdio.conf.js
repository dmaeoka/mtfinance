require("dotenv").config();

const { UtamWdioService } = require("wdio-utam-service");
// use prefix 'DEBUG=true' to run test in debug mode
const { DEBUG } = process.env;
const TIMEOUT = DEBUG ? 60 * 1000 * 30 : 60 * 1000;

exports.config = {
  runner: "local",
  specs: ["force-app/test/**/*.spec.js"],
  maxInstances: 1,
  capabilities: [
    {
      maxInstances: 1,
      browserName: "chrome",
      "goog:chromeOptions": {
        args: ["--disable-search-engine-choice-screen"]
        // to run chrome headless the following flags are required
        // (see https://developers.google.com/web/updates/2017/04/headless-chrome)
        //args: ['--headless', '--disable-gpu', '--window-size=1920,1080', '--disable-search-engine-choice-screen']
      }
    }
  ],
  logLevel: "debug",
  bail: 0,
  // timeout for all waitFor commands
  waitforTimeout: TIMEOUT,
  connectionRetryTimeout: 120000,
  connectionRetryCount: 3,
  automationProtocol: "webdriver",
  services: [
    "chromedriver",
    [
      UtamWdioService,
      {
        implicitTimeout: 0,
        injectionConfigs: [
          "salesforce-pageobjects/ui-global-components.config.json"
        ]
      }
    ]
  ],
  framework: "jasmine",
  reporters: ["spec"],
  jasmineOpts: {
    // max execution time for a script, set to 5 min
    defaultTimeoutInterval: 1000 * 60 * 5
  }
};
