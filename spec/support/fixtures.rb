def create_file_tree
  FileUtils.mkdir "dir1"
  FileUtils.touch "dir1/file1"
  FileUtils.mkdir "dir2"
  FileUtils.touch "dir2/file2"
end
