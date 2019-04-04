describe Fastlane::Actions::DynatraceAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The dynatrace plugin is working!")

      Fastlane::Actions::DynatraceAction.run(nil)
    end
  end
end
