import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

const root = "C:/Users/david/Documents/Development/Projects/afrobiomefoods-ios";
const appDir = path.join(root, "IgboFoodHeritage");
const used = new Set();

function pid(label) {
  let digest = crypto.createHash("sha1").update(label).digest("hex").slice(0, 24).toUpperCase();
  while (used.has(digest)) {
    digest = crypto.createHash("sha1").update(digest + label).digest("hex").slice(0, 24).toUpperCase();
  }
  used.add(digest);
  return digest;
}

const ids = {
  product: "A10000000000000000000002",
  target: "A10000000000000000000003",
  sourcesPhase: "A10000000000000000000004",
  resourcesPhase: "A10000000000000000000005",
  targetConfigs: "A10000000000000000000006",
  project: "A10000000000000000000007",
  projectConfigs: "A10000000000000000000009",
  mainGroup: "A1000000000000000000000A",
  productsGroup: "A1000000000000000000000B",
  frameworksPhase: "A1000000000000000000000C",
  debugProject: "A1000000000000000000000D",
  releaseProject: "A1000000000000000000000E",
  debugTarget: "A1000000000000000000000F",
  releaseTarget: "A10000000000000000000010",
  appGroup: "A10000000000000000000011",
  resourcesGroup: "A10000000000000000000012",
  imagesGroup: "A10000000000000000000013",
};
for (const id of Object.values(ids)) used.add(id);

function fileType(name) {
  const ext = path.extname(name).toLowerCase();
  if (ext === ".swift") return "sourcecode.swift";
  if (ext === ".json") return "text.json";
  if (ext === ".plist") return "text.plist.xml";
  if (ext === ".png") return "image.png";
  if (ext === ".jpg" || ext === ".jpeg") return "image.jpeg";
  return "file";
}

const swiftFiles = fs.readdirSync(appDir).filter((name) => name.endsWith(".swift")).sort();
const imageFiles = fs.readdirSync(path.join(appDir, "Resources", "Images")).sort();

const files = [];
function add(name, kind) {
  const ref = pid(`ref:${kind}:${name}`);
  const build = pid(`build:${kind}:${name}`);
  files.push({ name, kind, ref, build, type: fileType(name) });
  return files[files.length - 1];
}

const swift = swiftFiles.map((name) => add(name, "source"));
const catalog = add("catalog.json", "resource");
const images = imageFiles.map((name) => add(name, "image"));
const assets = add("Assets.xcassets", "asset");
assets.type = "folder.assetcatalog";
const infoPlist = add("Info.plist", "plist");

function q(name) {
  return /[^A-Za-z0-9._-]/.test(name) ? `"${name}"` : name;
}

const buildFiles = [...swift, catalog, ...images, assets]
  .map((file) => {
    const phase = file.kind === "source" ? "Sources" : "Resources";
    return `\t\t${file.build} /* ${file.name} in ${phase} */ = {isa = PBXBuildFile; fileRef = ${file.ref} /* ${file.name} */; };`;
  })
  .join("\n");

const fileRefs = [infoPlist, ...swift, catalog, ...images, assets]
  .map((file) => `\t\t${file.ref} /* ${file.name} */ = {isa = PBXFileReference; lastKnownFileType = ${file.type}; path = ${q(file.name)}; sourceTree = "<group>"; };`)
  .join("\n");

const sourcePhaseFiles = swift.map((file) => `\t\t\t\t${file.build} /* ${file.name} in Sources */,`).join("\n");
const resourcePhaseFiles = [catalog, ...images, assets]
  .map((file) => `\t\t\t\t${file.build} /* ${file.name} in Resources */,`)
  .join("\n");
const swiftChildren = swift.map((file) => `\t\t\t\t${file.ref} /* ${file.name} */,`).join("\n");
const imageChildren = images.map((file) => `\t\t\t\t${file.ref} /* ${file.name} */,`).join("\n");

const targetSettings = `
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 5;
				ENABLE_BITCODE = NO;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = IgboFoodHeritage/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = "Igbo Food Heritage";
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.food-and-drink";
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UIStatusBarStyle = UIStatusBarStyleDarkContent;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0.3;
				PRODUCT_BUNDLE_IDENTIFIER = com.afrobiomefoods.igbofoodheritage;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
`;

const project = `// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
${buildFiles}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		${ids.product} /* IgboFoodHeritage.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = IgboFoodHeritage.app; sourceTree = BUILT_PRODUCTS_DIR; };
${fileRefs}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		${ids.frameworksPhase} /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		${ids.mainGroup} = {
			isa = PBXGroup;
			children = (
				${ids.appGroup} /* IgboFoodHeritage */,
				${ids.productsGroup} /* Products */,
			);
			sourceTree = "<group>";
		};
		${ids.appGroup} /* IgboFoodHeritage */ = {
			isa = PBXGroup;
			children = (
${swiftChildren}
				${infoPlist.ref} /* Info.plist */,
				${assets.ref} /* Assets.xcassets */,
				${ids.resourcesGroup} /* Resources */,
			);
			path = IgboFoodHeritage;
			sourceTree = "<group>";
		};
		${ids.resourcesGroup} /* Resources */ = {
			isa = PBXGroup;
			children = (
				${catalog.ref} /* catalog.json */,
				${ids.imagesGroup} /* Images */,
			);
			path = Resources;
			sourceTree = "<group>";
		};
		${ids.imagesGroup} /* Images */ = {
			isa = PBXGroup;
			children = (
${imageChildren}
			);
			path = Images;
			sourceTree = "<group>";
		};
		${ids.productsGroup} /* Products */ = {
			isa = PBXGroup;
			children = (
				${ids.product} /* IgboFoodHeritage.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		${ids.target} /* IgboFoodHeritage */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = ${ids.targetConfigs} /* Build configuration list for PBXNativeTarget "IgboFoodHeritage" */;
			buildPhases = (
				${ids.sourcesPhase} /* Sources */,
				${ids.frameworksPhase} /* Frameworks */,
				${ids.resourcesPhase} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = IgboFoodHeritage;
			productName = IgboFoodHeritage;
			productReference = ${ids.product} /* IgboFoodHeritage.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		${ids.project} /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1420;
				LastUpgradeCheck = 1420;
				TargetAttributes = {
					${ids.target} = {
						CreatedOnToolsVersion = 14.2;
					};
				};
			};
			buildConfigurationList = ${ids.projectConfigs} /* Build configuration list for PBXProject "IgboFoodHeritage" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = ${ids.mainGroup};
			productRefGroup = ${ids.productsGroup} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				${ids.target} /* IgboFoodHeritage */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		${ids.resourcesPhase} /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
${resourcePhaseFiles}
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		${ids.sourcesPhase} /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
${sourcePhaseFiles}
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		${ids.debugProject} /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		${ids.releaseProject} /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		${ids.debugTarget} /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {${targetSettings}			};
			name = Debug;
		};
		${ids.releaseTarget} /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {${targetSettings}			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		${ids.targetConfigs} /* Build configuration list for PBXNativeTarget "IgboFoodHeritage" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				${ids.debugTarget} /* Debug */,
				${ids.releaseTarget} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		${ids.projectConfigs} /* Build configuration list for PBXProject "IgboFoodHeritage" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				${ids.debugProject} /* Debug */,
				${ids.releaseProject} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = ${ids.project} /* Project object */;
}
`;

const out = path.join(root, "IgboFoodHeritage.xcodeproj", "project.pbxproj");
fs.writeFileSync(out, project);
console.log(JSON.stringify({ swift: swift.length, images: images.length, ids: used.size }));
