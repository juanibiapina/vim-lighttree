require "support/fixtures"

RSpec.describe "LightTreeFind" do
  it "reveals a file in a tree" do
    create_file_tree
    vim.edit 'dir1/file1'

    vim.command 'LightTreeFind'

    result = vim.command 'echo getline(2)'
    expect(result).to eq("▾ dir1/")

    result = vim.command 'echo getline(3)'
    expect(result).to eq("    file1")
  end

  it "reveals a new file in a tree" do
    create_file_tree
    vim.edit 'dir1/file1'
    vim.command 'LightTreeFind'
    vim.edit 'dir1/new_file'
    vim.write

    vim.command 'LightTreeFind'

    result = vim.command 'echo getline(2)'
    expect(result).to eq("▾ dir1/")

    result = vim.command 'echo getline(4)'
    expect(result).to eq("    new_file")
  end
end
