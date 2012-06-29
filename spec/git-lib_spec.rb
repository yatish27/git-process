require 'git-lib'
require 'GitRepoHelper'

describe Git::GitLib do

  describe "status" do
    include GitRepoHelper

    before(:each) do
      create_files(['.gitignore'])
      gitlib.commit('initial')
    end


    after(:each) do
      rm_rf(@tmpdir)
    end


    it "should handle added files" do
      create_files(['a', 'b', 'c'])

      gitlib.status.added.should == ['a', 'b', 'c']
    end


    it "should handle a modification on both sides" do
      change_file_and_commit('a', '')

      gitlib.checkout('fb', :new_branch => 'master')
      change_file_and_commit('a', 'hello')

      gitlib.checkout('master')
      change_file_and_commit('a', 'goodbye')

      gitlib.merge('fb') rescue

      status = gitlib.status
      status.unmerged.should == ['a']
      status.modified.should == ['a']
    end


    it "should handle an addition on both sides" do
      gitlib.checkout('fb', :new_branch => 'master')
      change_file_and_commit('a', 'hello')

      gitlib.checkout('master')
      change_file_and_commit('a', 'goodbye')

      gitlib.merge('fb') rescue

      status = gitlib.status
      status.unmerged.should == ['a']
      status.added.should == ['a']
    end


    it "should handle a merge deletion on fb" do
      change_file_and_commit('a', '')

      gitlib.checkout('fb', :new_branch => 'master')
      gitlib.remove('a', :force => true)
      gitlib.commit('removed a')

      gitlib.checkout('master')
      change_file_and_commit('a', 'goodbye')

      gitlib.merge('fb') rescue

      status = gitlib.status
      status.unmerged.should == ['a']
      status.deleted.should == ['a']
    end


    it "should handle a merge deletion on master" do
      change_file_and_commit('a', '')

      gitlib.checkout('fb', :new_branch => 'master')
      change_file_and_commit('a', 'hello')

      gitlib.checkout('master')
      gitlib.remove('a', :force => true)
      gitlib.commit('removed a')

      gitlib.merge('fb') rescue

      status = gitlib.status
      status.unmerged.should == ['a']
      status.deleted.should == ['a']
    end


    it "should return an empty result" do
      gitlib.status.added.should == []
      gitlib.status.deleted.should == []
      gitlib.status.modified.should == []
      gitlib.status.unmerged.should == []
    end

  end


  describe "branches" do
    include GitRepoHelper

    it "list all the branches" do
      create_files(['.gitignore'])
      gitlib.commit('initial')

      gitlib.branch('ba', :base_branch => 'master')
      gitlib.branch('bb', :base_branch => 'master')
      gitlib.branch('origin/master', :base_branch => 'master')

      gitlib.branches.names.should == ['ba', 'bb', 'master', 'origin/master']
    end

  end


  describe "branch" do
    attr_reader :lib

    before(:each) do
      @lib = Git::GitLib.new(nil, :git => double('git'))
    end


    it "should create a branch with default base" do
      lib.stub(:command).with(:branch, ['test_branch', 'master'])
      lib.branch('test_branch')
    end


    it "should create a branch with explicit base" do
      lib.stub(:command).with(:branch, ['test_branch', 'other_branch'])
      lib.branch('test_branch', :base_branch => 'other_branch')
    end


    it "should delete a branch without force" do
      lib.stub(:command).with(:branch, ['-d', 'test_branch'])
      lib.branch('test_branch', :delete => true)
    end


    it "should delete a branch with force" do
      lib.stub(:command).with(:branch, ['-D', 'test_branch'])
      lib.branch('test_branch', :delete => true, :force => true)
    end

  end


  describe "push" do
    attr_reader :lib

    before(:each) do
      @lib = Git::GitLib.new(nil, :git => double('git'))
    end


    def log_level
      Logger::ERROR
    end


    it "should push local branch to remote" do
      lib.should_receive(:command).with(:push, ['remote', 'local_branch:test_branch'])

      lib.push('remote', 'local_branch', 'test_branch')
    end


    it "should push current branch to remote" do
      lib.stub(:command).with(:branch, ['-a', '--no-color']).and_return("* my_branch\n")
      lib.should_receive(:command).with(:push, ['remote', 'my_branch:my_branch'])

      lib.push('remote', 'my_branch', nil)
    end


    it "should remove named branch on remote" do
      lib.should_receive(:command).with(:push, ['remote', '--delete', 'my_branch'])

      lib.push('remote', 'my_branch', nil, :delete => true)
    end


    it "should remove current branch on remote" do
      lib.should_receive(:command).with(:push, ['remote', '--delete', 'my_branch'])

      lib.push('remote', nil, nil, :delete => 'my_branch')
    end


    # it "should create a branch with explicit base" do
    #   lib.stub(:command).with(:branch, ['test_branch', 'other_branch'])
    #   lib.branch('test_branch', :base_branch => 'other_branch')
    # end


    # it "should delete a branch without force" do
    #   lib.stub(:command).with(:branch, ['-d', 'test_branch'])
    #   lib.branch('test_branch', :delete => true)
    # end


    # it "should delete a branch with force" do
    #   lib.stub(:command).with(:branch, ['-D', 'test_branch'])
    #   lib.branch('test_branch', :delete => true, :force => true)
    # end

  end

end
