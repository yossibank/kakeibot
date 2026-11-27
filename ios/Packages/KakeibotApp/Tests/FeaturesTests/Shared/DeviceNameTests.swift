@testable import FeatureModels
@testable import Features
import Testing

struct DeviceNameTests {
    @Test
    func namesPadModelsAsPad() {
        #expect(DeviceName.name(ofModel: "iPad16,3") == "iPad")
    }

    @Test
    func namesOtherModelsAsPhone() {
        #expect(DeviceName.name(ofModel: "iPhone17,3") == "iPhone")
        #expect(DeviceName.name(ofModel: "arm64") == "iPhone")
    }

    @Test
    func namesKnownModelsAndKeepsUnknownIdentifiers() {
        #expect(DeviceName.modelName(ofModel: "iPhone18,3") == "iPhone 17")
        #expect(DeviceName.modelName(ofModel: "iPhone18,1") == "iPhone 17 Pro")
        #expect(DeviceName.modelName(ofModel: "iPad16,3") == "iPad Pro 11インチ（M4）")
        #expect(DeviceName.modelName(ofModel: "iPhone99,1") == "iPhone99,1")
    }
}
