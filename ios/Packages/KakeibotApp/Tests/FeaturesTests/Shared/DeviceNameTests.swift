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
}
