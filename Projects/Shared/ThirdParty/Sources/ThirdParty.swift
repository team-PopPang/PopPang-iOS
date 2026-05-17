import Foundation

// Dependency hub for external SDKs.
// Modules that depend on `ThirdParty` should import the concrete SDK module name
// such as `FirebaseCore`, `Moya`, or `Kingfisher` where they actually use it.
// Do not add empty marker namespaces here unless we intentionally introduce wrappers.
public enum ThirdPartyModule {
}
