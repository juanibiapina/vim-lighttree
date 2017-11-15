require "support/fixtures"

RSpec.describe "LightTree" do
  before do
    create_file_tree
  end

  it "opens the light tree explorer" do
    vim.command 'LightTree'

    result = vim.command 'echo getline(2)'
    expect(result).to eq("▸ dir1/")
  end

  describe "when pressing enter on a directory" do
    it "expands the directory" do
      vim.command 'LightTree'

      vim.feedkeys 'j\<CR>'

      result = vim.command 'echo getline(2)'
      expect(result).to eq("▾ dir1/")
    end

    it "lists the files in the directory" do
      vim.command 'LightTree'

      vim.feedkeys 'j\<CR>'

      result = vim.command 'echo getline(3)'
      expect(result).to eq("    file1")
    end
  end
end
