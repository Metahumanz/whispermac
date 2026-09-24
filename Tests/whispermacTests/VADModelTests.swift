import Foundation
import Testing
@testable import whispermac

@Suite
struct VADModelTests {
    @Test
    func settingsUseDocumentedDefaultsAndClampInvalidRanges() {
        #expect(VADSettings.default == VADSettings())
        let settings = VADSettings(
            threshold: .infinity,
            minSpeechDurationMs: -1,
            minSilenceDurationMs: 99_000,
            speechPadMs: -50
        )
        #expect(settings.threshold == 0.5)
        #expect(settings.minSpeechDurationMs == 0)
        #expect(settings.minSilenceDurationMs == 10_000)
        #expect(settings.speechPadMs == 0)
    }

    @Test
    func settingsCodableRoundTrip() throws {
        let settings = VADSettings(isEnabled: true, modelPath: "/tmp/silero.bin", threshold: 0.63)
        let data = try JSONEncoder().encode(settings)
        #expect(try JSONDecoder().decode(VADSettings.self, from: data) == settings)
    }

    @Test
    func automaticDiscoveryFindsPreferredModelName() throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let model = root.appending(path: VADModelResolver.fileName)
        try writeValidModel(to: model)
        #expect(VADModelResolver.resolve("", searchRoots: [root]) == model.path)
    }

    @Test
    func manualPathIsAcceptedAndMissingPathIsRejected() throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let model = root.appending(path: "custom-silero.bin")
        try writeValidModel(to: model)
        #expect(VADModelResolver.resolve(model.path) == model.path)
        #expect(VADModelResolver.resolve(root.appending(path: "missing.bin").path).isEmpty)
    }

    @Test
    func vadDownloadURLUsesOfficialRepositoryAndAsset() {
        let url = HuggingFaceEndpoint.assetURL(
            fileName: VADModelResolver.fileName,
            baseURL: HuggingFaceEndpoint.defaultBaseURL,
            repository: "ggml-org/whisper-vad"
        )
        #expect(url.absoluteString == "https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin?download=true")
        #expect(HuggingFaceEndpoint.treeAPIURL(
            baseURL: HuggingFaceEndpoint.defaultBaseURL,
            repository: "ggml-org/whisper-vad"
        ).absoluteString == "https://huggingface.co/api/models/ggml-org/whisper-vad/tree/main?recursive=true")
    }

    @Test
    func vadFileValidationUsesCompactModelSizeThreshold() throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let model = root.appending(path: "small.bin")
        try Data(repeating: 1, count: Int(VADModelResolver.minimumBytes) - 1).write(to: model)
        let tooSmall = try DownloadValidator.validate(
            fileAt: model,
            expectation: DownloadExpectation(
                minimumBytes: VADModelResolver.minimumBytes,
                expectedDigest: nil,
                requiredMagicBytes: nil
            )
        )
        #expect(tooSmall == .rejected(.belowMinimumSize(
            minimumBytes: VADModelResolver.minimumBytes,
            actualBytes: VADModelResolver.minimumBytes - 1
        )))
    }

    private func makeDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func writeValidModel(to url: URL) throws {
        var data = DownloadExpectation.ggmlMagic
        data.append(Data(repeating: 0, count: Int(VADModelResolver.minimumBytes) - data.count))
        try data.write(to: url)
    }
}
