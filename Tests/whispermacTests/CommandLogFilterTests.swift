import Testing
@testable import whispermac

@Test
func whisperStdoutTranscriptIsDropped() {
    let filtered = CommandLogFilter.filteredLine(
        for: .stdout,
        tool: .whisper,
        line: "[00:00:00.000 --> 00:00:02.000]  大家好"
    )

    #expect(filtered == nil)
}

@Test
func whisperProgressLineIsKept() {
    let filtered = CommandLogFilter.filteredLine(
        for: .stderr,
        tool: .whisper,
        line: "whisper_print_progress_callback: progress =  35%"
    )

    #expect(filtered == "whisper_print_progress_callback: progress =  35%")
}

@Test
func audioPreprocessorErrorLineIsKept() {
    let filtered = CommandLogFilter.filteredLine(
        for: .stderr,
        tool: .audioPreprocessor,
        line: "Error: cannot decode input file"
    )

    #expect(filtered == "Error: cannot decode input file")
}

@Test
func vadSummaryAndFailureLinesAreKept() {
    #expect(CommandLogFilter.filteredLine(
        for: .stderr,
        tool: .whisper,
        line: "whisper_vad_detect_speech: detected 8 speech segments, total speech duration 12.4 s"
    ) != nil)
    #expect(CommandLogFilter.filteredLine(
        for: .stderr,
        tool: .whisper,
        line: "VAD model version: Silero v6.2.0"
    ) != nil)
    #expect(CommandLogFilter.filteredLine(
        for: .stderr,
        tool: .whisper,
        line: "whisper_vad_process: failed to decode model"
    ) != nil)
}

@Test
func repetitiveVADWindowLinesAreFiltered() {
    #expect(CommandLogFilter.filteredLine(
        for: .stderr,
        tool: .whisper,
        line: "whisper_vad_process: processing internal window 281"
    ) == nil)
}
