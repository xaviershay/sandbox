# Tasks related to capturing and reporting on build metrics, such as run
# time and code quality.
namespace :build do
  desc "Run specs and store the time taken in a git note on HEAD"
  task :time do
    # ruby/rake are not aliased by rvm in the new zsh environment, so
    # have to explicitly call it using the rvm command stored in .rvmrc:
    #   rvm 1.9.2@lindylog rake
    #
    # "2> >( )" construct redirects STDERR (where @time@ prints to) to the
    # bracketed commands. ZSH allows us to redirect it twice, once to git,
    # once to cat (back to STDOUT).
    formatter = "tail -n 1 | cut -f 12 -d ' ' - "
    exec((%{zsh -c "(time `cat .rvmrc` rake spec) } + 
          %{2> >(#{formatter} | git notes --ref=buildtime add -F - -f ) } +
          %{2> >(#{formatter} | cat)"}).tap {|x| puts x })
  end
end

desc "Run specs with build metrics, storing the values in a git note on HEAD"
task :build => :'build:time'
