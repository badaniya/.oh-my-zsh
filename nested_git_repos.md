[Go Back to the Main README](README.md)

## How Nested Git Repositories Are Configured - For Reference ONLY
### 1) tmux
```console
# TPM - TMUX Plugin Manager
cd $HOME/.stowed
git remote add tpm https://github.com/tmux-plugins/tpm
git remote add tpm https://github.com/tmux-plugins/tmux-sensible
git remote add catppuccin https://github.com/catppuccin/tmux
git remote add vim-tmux-navigator https://github.com/christoomey/vim-tmux-navigator
git remote add tmux-resurrect https://github.com/tmux-plugins/tmux-resurrect
git remote add tmux-continuum https://github.com/tmux-plugins/tmux-continuum
git subtree add --prefix=tmux/.tmux/plugins/tpm tpm master --squash
git subtree add --prefix=tmux/.tmux/plugins/tmux-sensible master --squash
git subtree add --prefix=tmux/.tmux/plugins/tmux catppuccin main --squash
git subtree add --prefix=tmux/.tmux/plugins/vim-tmux-navigator vim-tmux-navigator master --squash
git subtree add --prefix=tmux/.tmux/plugins/tmux-resurrect tmux-resurrect master --squash
git subtree add --prefix=tmux/.tmux/plugins/tmux-continuum tmux-continuum master --squash
```

### 2) zsh
```console
# Oh My ZSH Repo
cd $HOME/.stowed
git remote add oh-my-zsh https://github.com/badaniya/.oh-my-zsh
git subtree add --prefix=zsh/.oh-my-zsh oh-my-zsh master

# ZSH Plugins
git remote add zsh-sytax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting
git remote add zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions
git remote add last-working-dir-tmux https://github.com/badaniya/last-working-dir-tmux
git subtree add --prefix=zsh/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting zsh-sytax-highlighting master --squash
git subtree add --prefix=zsh/.oh-my-zsh/custom/plugins/zsh-autosuggestions zsh-autosuggestions master --squash
git subtree add --prefix=zsh/.oh-my-zsh/custom/plugins/last-working-dir-tmux last-working-dir-tmux master --squash
```

### 3) nvim
```console
# NVIM Repo
cd $HOME/.stowed
git remote add nvim https://github.com/badaniya/nvim
git subtree add --prefix=nvim/.config/nvim nvim master
```

### 4) vim
```console
# VIM Repo
cd $HOME/.stowed
git remote add ferret https://github.com/wincent/ferret.git
git remote add lightline.vim https://github.com/itchyny/lightline.vim
git remote add nerdtree https://github.com/preservim/nerdtree
git remote add nerdtree-git-plugin https://github.com/Xuyuanp/nerdtree-git-plugin
git remote add vim-fugitive https://github.com/tpope/vim-fugitive
git remote add vim-gitgutter https://github.com/airblade/vim-gitgutter
git remote add vim-go https://github.com/fatih/vim-go
git subtree add --prefix=vim/.vim/plugged/ferret ferret master --squash
git subtree add --prefix=vim/.vim/plugged/lightline.vim lightline.vim master --squash
git subtree add --prefix=vim/.vim/plugged/nerdtree nerdtree master --squash
git subtree add --prefix=vim/.vim/plugged/nerdtree-git-plugin nerdtree-git-plugin master --squash
git subtree add --prefix=vim/.vim/plugged/vim-fugitive vim-fugitive master --squash
git subtree add --prefix=vim/.vim/plugged/vim-go vim-go master --squash
git subtree add --prefix=vim/.vim/plugged/vim-gitgutter vim-gitgutter main --squash
```
