// Based on issues in RN CarPlay and https://github.com/birkir/react-native-carplay/pull/158/files

import {
    ConfigPlugin,
    IOSConfig,
    XcodeProject,
    createRunOncePlugin,
    withDangerousMod,
    withEntitlementsPlist,
    withInfoPlist,
    withXcodeProject,
  } from 'expo/config-plugins';
  
  import * as fs from 'fs/promises';
  import * as path from 'path';
  
  let xcodeProjectName = '';
  
  export const withCarPlay: ConfigPlugin = config => {  
    xcodeProjectName = config.name;
  
    config = withCarPlayAppDelegateHeader(config);
    config = withCarPlayAppDelegate(config);
    config = withCarPlayInfoPlist(config);
    config = withCarPlayEntitlements(config);
  
    config = withCarPlayScenesFiles(config);
    config = withCarPlayScenesInProject(config);
    return config;
  };
  
  export const withCarPlayAppDelegate: ConfigPlugin = config => {
    return withDangerousMod(config, [
      'ios',
      async config => {
        const fileInfo = IOSConfig.Paths.getAppDelegate(config.modRequest.projectRoot);
        let contents = await fs.readFile(fileInfo.path, 'utf-8');
        if (fileInfo.language === 'objcpp' || fileInfo.language === 'objc') {
          contents = await modifySourceFile(config.modRequest.projectRoot, contents);
        } else {
          throw new Error(`Cannot add CarPlay code to AppDelegate of language "${fileInfo.language}"`);
        }
        await fs.writeFile(fileInfo.path, contents);
        return config;
      },
    ]);
  };
  
  export const withCarPlayAppDelegateHeader: ConfigPlugin = config => {
    return withDangerousMod(config, [
      'ios',
      async config => {
        const headerFilePath = IOSConfig.Paths.getAppDelegateHeaderFilePath(config.modRequest.projectRoot);
        let contents = await fs.readFile(headerFilePath, 'utf-8');
  
        contents = await modifyHeaderFile(config.modRequest.projectRoot, contents);
  
        await fs.writeFile(headerFilePath, contents);
        return config;
      },
    ]);
  };
  
  const withCarPlayEntitlements: ConfigPlugin = config => {
    return withEntitlementsPlist(config, config => {
      config.modResults['com.apple.developer.carplay-audio'] = true;
      return config;
    });
  };
  
  export const withCarPlayInfoPlist: ConfigPlugin = config => {
    return withInfoPlist(config, async config => {
      const xcodeProject = config.modResults;
  
      // Multiple scenes
      xcodeProject.UIApplicationSceneManifest = {
        UIApplicationSupportsMultipleScenes: false,
        UISceneConfigurations: {
          UIWindowSceneSessionRoleApplication: [
            {
              UISceneClassName: 'UIWindowScene',
              UISceneConfigurationName: 'Phone',
              UISceneDelegateClassName: 'SceneDelegate',
            },
          ],
          CPTemplateApplicationSceneSessionRoleApplication: [
            {
              UISceneClassName: 'CPTemplateApplicationScene',
              UISceneConfigurationName: 'CarPlay',
              UISceneDelegateClassName: 'CarSceneDelegate',
            },
          ],
        },
      };
  
      return config;
    });
  };
  
  const withCarPlayScenesInProject: ConfigPlugin = config => {
    return withXcodeProject(config, async config => {
      addSourceFileToProject(config.modResults, xcodeProjectName + '/CarSceneDelegate.h');
      addSourceFileToProject(config.modResults, xcodeProjectName + '/CarSceneDelegate.mm');
  
      addSourceFileToProject(config.modResults, xcodeProjectName + '/SceneDelegate.h');
      addSourceFileToProject(config.modResults, xcodeProjectName + '/SceneDelegate.mm');
  
      return config;
    });
  };
  
  const withCarPlayScenesFiles: ConfigPlugin = config => {
    return withDangerousMod(config, [
      'ios',
      async config => {
        const projectPath = IOSConfig.Paths.getAppDelegateHeaderFilePath(config.modRequest.projectRoot);
  
        const dir = path.dirname(projectPath);
  
        fs.copyFile(
          config.modRequest.projectRoot + '/plugins/carplay/CarSceneDelegate.h',
          path.join(dir, 'CarSceneDelegate.h'),
        );
        fs.copyFile(
          config.modRequest.projectRoot + '/plugins/carplay/CarSceneDelegate.mm',
          path.join(dir, 'CarSceneDelegate.mm'),
        );
        fs.copyFile(
          config.modRequest.projectRoot + '/plugins/carplay/SceneDelegate.h',
          path.join(dir, 'SceneDelegate.h'),
        );
        fs.copyFile(
          config.modRequest.projectRoot + '/plugins/carplay/SceneDelegate.mm',
          path.join(dir, 'SceneDelegate.mm'),
        );
  
        return config;
      },
    ]);
  };
  
  const modifyHeaderFile = async (projectRoot: string, contents: string): Promise<string> => {
    const addedContents = await getFileContents(projectRoot, 'AppDelegate.add.h');
  
    contents = contents.replace(/@interface AppDelegate\s?:\s?EXAppDelegateWrapper?/, (_a, _b) => addedContents);
  
    return contents;
  };
  
  const modifySourceFile = async (projectRoot: string, contents: string): Promise<string> => {
    // update imports
    const imports = await getFileContents(projectRoot, 'AppDelegate.imports.mm');
  
    contents = imports + contents;
  
    const newAppDelegateMethods = await getFileContents(projectRoot, 'AppDelegate.endMethods.mm');
  
    // Extra method at the end!
    contents = contents.replace(/@end/, newAppDelegateMethods + '\n@end');
  
    const topAppDelegateMethods = await getFileContents(projectRoot, 'AppDelegate.topMethods.mm');
    // add extra methods at the top:
    contents = contents.replace(/@implementation AppDelegate/, topAppDelegateMethods);
  
    contents = contents.replace(
      'return [super application:application didFinishLaunchingWithOptions:launchOptions];',
      'return YES;',
    );
  
    return contents;
  };
  
  const getFileContents = async (projectRoot: string, fileName: string): Promise<string> => {
    return await fs.readFile(projectRoot + '/plugins/carplay/' + fileName, 'utf-8');
  };
  
  const addSourceFileToProject = (proj: XcodeProject, file: string) => {
    const targetUuid = proj.findTargetKey(xcodeProjectName);
  
    const groupUuid = proj.findPBXGroupKey({ name: xcodeProjectName });
  
    if (!targetUuid) {
      console.error(`Failed to find "${xcodeProjectName}" target!`);
      return;
    }
    if (!groupUuid) {
      console.error(`Failed to find "${xcodeProjectName}" group!`);
      return;
    }
  
    proj.addSourceFile(
      file,
      {
        target: targetUuid,
      },
      groupUuid,
    );
  };
  
  const withCarPlayPlugin: ConfigPlugin = config => {
    config = withCarPlay(config);
  
    // Return the modified config.
    return config;
  };
  
  const pkg = {
    // Prevent this plugin from being run more than once.
    name: '@zetland/react-native-carplay',
    // Indicates that this plugin is dangerously linked to a module,
    // and might not work with the latest version of that module.
    version: 'UNVERSIONED',
  };
  
  export default createRunOncePlugin(withCarPlayPlugin, pkg.name, pkg.version);
  