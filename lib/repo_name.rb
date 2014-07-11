# encoding: UTF-8

RepoName = Struct.new(:owner, :repo) do
  def self.parse(str)
    new(*str.split('/'))
  end

  def to_s
    "#{owner}/#{repo}"
  end
end