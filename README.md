# Expo CarPlay plugin

Expo config plugin for react-native-carplay with Expo SDK 51 and React Native 0.75
It allows to run the CarPlay app without running the iOS phone app first.

# Installation

Add the plugin to the plugins array in app.config.ts

```
plugins: [
  require("./plugins/carplay/withCarPlay").withCarPlay,
]
```

Since the plugin is written in TypeScript you should compile the plugin to JavaScript yourself, or run ts-node by installing ts-node as devDependency, and calling ts-node on top of your app.config.js like this:

```
/**
 * Use ts-node here so we can use TypeScript for our Config Plugins
 * and not have to compile them to JavaScript
 */
require("ts-node/register")
```

## Known Issue

When the package expo-dev-client is installed and the development client is used, the initial launch on the CarPlay device / simulator does not work.
It does boot when the phone app is launched.

When running a preview/production build, this issue does not occur.
