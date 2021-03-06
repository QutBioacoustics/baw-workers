require 'spec_helper'

describe BawWorkers::Storage::AudioOriginal do

  let(:audio_original) { BawWorkers::Config.original_audio_helper }

  let(:uuid) { '5498633d-89a7-4b65-8f4a-96aa0c09c619' }
  let(:datetime) { Time.zone.parse("2012-03-02 16:05:37+1100") }
  let(:partial_path) { uuid[0, 2] }
  let(:format_audio) { 'wav' }

  let(:original_format) { 'mp3' }
  let(:original_file_name_old) { "#{uuid}_120302-1505.#{original_format}" } # depends on let(:datetime)
  let(:original_file_name_new) { "#{uuid}_20120302-050537Z.#{original_format}" } # depends on let(:datetime)

  let(:opts) {
    {
        uuid: uuid,
        datetime_with_offset: datetime,
        original_format: original_format
    }
  }


  it 'no storage directories exist' do
    expect(audio_original.existing_dirs).to be_empty
  end

  it 'possible dirs match settings' do
    expect(audio_original.possible_dirs).to match_array BawWorkers::Settings.paths.original_audios
  end

  it 'existing dirs match settings' do
    Dir.mkdir(BawWorkers::Settings.paths.original_audios[0]) unless Dir.exists?(BawWorkers::Settings.paths.original_audios[0])
    expect(audio_original.existing_dirs).to match_array BawWorkers::Settings.paths.original_audios
    FileUtils.rm_rf(BawWorkers::Settings.paths.original_audios[0])
  end

  it 'possible paths match settings for old names' do
    files = [File.join(BawWorkers::Settings.paths.original_audios[0], partial_path, original_file_name_old)]
    expect(audio_original.possible_paths_file(opts, original_file_name_old)).to match_array files
  end

  it 'possible paths match settings for new names' do
    files = [File.join(BawWorkers::Settings.paths.original_audios[0], partial_path, original_file_name_new)]
    expect(audio_original.possible_paths_file(opts, original_file_name_new)).to match_array files
  end

  it 'existing paths match settings for old names' do
    files = [
        File.join(BawWorkers::Settings.paths.original_audios[0], partial_path, original_file_name_old)
    ]
    dir = BawWorkers::Settings.paths.original_audios[0]
    sub_dir = File.join(dir, partial_path)
    FileUtils.mkpath(sub_dir)
    FileUtils.touch(files[0])
    expect(audio_original.possible_paths_file(opts, original_file_name_old)).to match_array files
    FileUtils.rm_rf(dir)
  end

  it 'existing paths match settings for new names' do
    files = [File.join(BawWorkers::Settings.paths.original_audios[0], partial_path, original_file_name_new)]
    dir = BawWorkers::Settings.paths.original_audios[0]
    sub_dir = File.join(dir, partial_path)
    FileUtils.mkpath(sub_dir)
    FileUtils.touch(files[0])
    expect(audio_original.possible_paths_file(opts, original_file_name_new)).to match_array files
    FileUtils.rm_rf(dir)
  end

  it 'creates the correct old name' do
    expect(audio_original.file_name_10(opts)).to eq original_file_name_old
  end

  it 'creates the correct new name' do
    expect(audio_original.file_name_utc(opts)).to eq original_file_name_new
  end

  it 'creates the correct partial path for old names' do
    expect(audio_original.partial_path(opts)).to eq partial_path
  end

  it 'creates the correct partial path for new names' do
    expect(audio_original.partial_path(opts)).to eq partial_path
  end

  it 'creates the correct full path for old names' do
    expected = [File.join(BawWorkers::Settings.paths.original_audios[0], partial_path, original_file_name_old)]
    expect(audio_original.possible_paths_file(opts, original_file_name_old)).to eq expected
  end

  it 'creates the correct full path for new names for a single file' do
    expected = [File.join(BawWorkers::Settings.paths.original_audios[0], partial_path, original_file_name_new)]
    expect(audio_original.possible_paths_file(opts, original_file_name_new)).to eq expected
  end

  it 'creates the correct full path' do
    expected = [
        File.join(BawWorkers::Settings.paths.original_audios[0], partial_path, original_file_name_old),
        File.join(BawWorkers::Settings.paths.original_audios[0], partial_path, original_file_name_new)
    ]
    expect(audio_original.possible_paths(opts)).to eq expected
  end

  it 'detects that Date object is not valid' do
    expect {
      new_opts = opts.dup
      new_opts[:datetime_with_offset] = datetime.to_s
      audio_original.file_name_10(new_opts)
    }.to raise_error(ArgumentError, /datetime_with_offset must be an ActiveSupport::TimeWithZone/)
  end

  it 'parses a valid new file name correctly' do
    path = audio_original.possible_paths_file(opts, original_file_name_new)

    path_info = audio_original.parse_file_path(path[0])

    expect(path.size).to eq 1
    expect(path.first).to eq "./tmp/custom_temp_dir/_original_audio/54/5498633d-89a7-4b65-8f4a-96aa0c09c619_20120302-050537Z.mp3"

    expect(path_info[:uuid]).to eq uuid
    expect(path_info[:datetime_with_offset]).to eq datetime
    expect(path_info[:original_format]).to eq original_format
  end

  it 'parses a valid old file name correctly' do
    path = audio_original.possible_paths_file(opts, original_file_name_old)

    path_info = audio_original.parse_file_path(path[0])

    expect(path.size).to eq 1
    expect(path.first).to eq "./tmp/custom_temp_dir/_original_audio/54/5498633d-89a7-4b65-8f4a-96aa0c09c619_120302-1505.mp3"

    expect(path_info.keys.size).to eq 3
    expect(path_info[:uuid]).to eq uuid
    expect(path_info[:datetime_with_offset]).to eq datetime.change(sec: 0)
    expect(path_info[:original_format]).to eq original_format
  end

  it 'correctly enumerates no files in an empty storage directory' do
    files = []
    audio_original.existing_files { |file| files.push(file) }

    expect(files).to be_empty
  end

  it 'enumerates all files in the storage directory' do

    paths = audio_original.possible_paths(opts)
    paths.each do |path|
      FileUtils.mkpath(File.dirname(path))
      FileUtils.touch(path)
    end

    files = []
    audio_original.existing_files do |file|
      info = audio_original.parse_file_path(file)
      files.push(info.merge({file:file}))
    end

    expect(files.size).to eq(2)

    expect(files[0][:uuid]).to eq(uuid)
    expect(files[1][:uuid]).to eq(uuid)

    expect(files[0][:original_format]).to eq(original_format)
    expect(files[1][:original_format]).to eq(original_format)
  end

end