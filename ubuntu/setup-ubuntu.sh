#!/usr/bin/env bash

# Helper script to install different tools on a Ubuntu distribution if not
# already present. It also sets up packages related to my setup.

set -euo pipefail # safer than -eux

# $HOME will point to "/root" when run with sudo privileges if we are not
# careful.
HOME_DIR=$(eval echo ~"${SUDO_USER:-$USER}")
GITHUB="$HOME_DIR/github"
DOTFILES="$GITHUB/private-dotfiles"
CONFIG_DIR="$HOME_DIR/.config"
LOCAL_DIR="$HOME_DIR/.local"

DISTRO=$(lsb_release -is)
VERSION=$(lsb_release -sr)
DIST_VERSION="${DISTRO}_${VERSION}"

usage() {
    set +x
    echo "Usage: bash ./$0 <function>" 1>&2
    exit 1
}

is_sudo() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root!"
        exit 1
    fi
}

log() { echo "[$(date '+%F %T')] $*"; }

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

emacs() {
    sudo apt update && sudo apt build-dep -y emacs

    EMACS_VERSION="30.2"

    cd "$HOME" || echo "Failed: cd $HOME"
    EMACS_NAME="emacs-${EMACS_VERSION}"
    EMACS_FILENAME="${EMACS_NAME}.tar.xz"
    if [ ! -f "${EMACS_FILENAME}" ]; then
        wget https://ftp.gnu.org/gnu/emacs/"${EMACS_FILENAME}"
    fi
    tar xf "${EMACS_FILENAME}"
    rm "${EMACS_FILENAME}"* || true

    EMACS_SOURCE="$HOME/${EMACS_NAME}"
    chown -R "$USER":"$USER" "${EMACS_SOURCE}"
    cd "${EMACS_SOURCE}" || echo "Failed: cd ${EMACS_SOURCE}"

    # Use GCC 10 if you are on Ubuntu 20.04, not required for Ubuntu 22.04+. GCC
    # 11 is the default in Ubuntu 22.
    case "${DIST_VERSION}" in
    Ubuntu_18.04 | Ubuntu_20.04)
        export CC=/usr/bin/gcc-10 CXX=/usr/bin/g++-10
        ;;
    esac

    make distclean
    ./autogen.sh

    # The arguments are based on Emacs 30.
    ./configure --with-x-toolkit=no --with-gif=ifavailable --with-tiff=ifavailable --with-gnutls=ifavailable --disable-gc-mark-trace --enable-link-time-optimization CFLAGS="-O3 -mtune=native -march=native -fomit-frame-pointer -funroll-loops -floop-parallelize-all -flto" --prefix="$HOME/.local"

    # Use NATIVE_FULL_AOT=1 to native compile ahead-of-time all the Elisp files
    # included in the Emacs distribution instead of after startup, provided
    # native compilation is supported.
    make -j"$(nproc --ignore=2)"
    make install

    cd "$HOME" || echo "Failed: cd $HOME"
    rm "${EMACS_FILENAME}" || true
}

setup_emacs() {
    cd "$HOME" || echo "Failed: cd $HOME"

    mkdir -p "$HOME/.emacs.d/etc" && cd "$HOME/.emacs.d/etc" || exit

    # Overwrite otherwise creating symlink can fail on subsequent runs.
    ln -nsf "$DOTFILES/emacs/private.el" .

    wget https://languagetool.org/download/LanguageTool-stable.zip
    unzip -o LanguageTool-stable.zip -d languagetool
    rm LanguageTool-stable.zip

    # Setup 24bit terminal support. We do not need this with terminal emulators
    # like Alacritty, Kitty, and Ghostty.
    # tic -x -o "$HOME/.terminfo" "${DOTFILES}/xterm-24bit.terminfo"
}

# Install important packages. There is nothing to do if a package is already
# installed.
ubuntu_packages() {
    case "${DIST_VERSION}" in
    Ubuntu_18.04)
        sudo apt install -y aspell hunspell libxml2-utils chktex ruby-dev tidy python-pygments python-pip python3-pip imagemagick libmagick++-dev fonts-powerline pkg-config autoconf automake python3-docutils libseccomp-dev libjansson-dev libyaml-dev libxml2-dev autojump texinfo x11-utils ttf-ancient-fonts libmagickwand-dev cpanminus libjpeg-dev libtiff-dev libgif-dev libxpm-dev libgtk-3-dev libncurses5-dev libxt-dev htop unifont xfonts-terminus ttf-anonymous-pro libperl-dev libpng-dev libx11-dev libgtk2.0-dev librsvg2-dev gcc libtiff5-dev gnutls-bin libgnutls28-dev libharfbuzz-dev libharfbuzz-bin libwebkit2gtk-4.0-dev libxaw7-dev libc6-dev xaw3dg-dev zlib1g-dev libice-dev libsm-dev libxext-dev libxi-dev libxmu-dev libxmuu-dev libxrandr-dev libxtst-dev libxv-dev curl libssl-dev wget gpg
        ;;
    Ubuntu_20.04)
        sudo apt install -y aspell hunspell libxml2-utils chktex ruby-dev tidy python-pygments python3-pip composer imagemagick libmagick++-dev fonts-powerline pkg-config autoconf automake python3-docutils libseccomp-dev libjansson-dev libyaml-dev libxml2-dev autojump texinfo x11-utils ttf-ancient-fonts libmagickwand-dev cpanminus libjpeg-dev libtiff-dev libgif-dev libxpm-dev libgtk-3-dev libncurses5-dev libxt-dev htop unifont xfonts-terminus ttf-anonymous-pro libperl-dev libpng-dev libx11-dev libgtk2.0-dev librsvg2-dev gcc libtiff5-dev gnutls-bin libgnutls28-dev libharfbuzz-dev libharfbuzz-bin libwebkit2gtk-4.0-dev libxaw7-dev libc6-dev xaw3dg-dev zlib1g-dev libice-dev libsm-dev libxext-dev libxi-dev libxmu-dev libxmuu-dev libxrandr-dev libxtst-dev libxv-dev curl libssl-dev wget gpg libenchant-2-dev libwebp-dev webp libxft-dev libxft2 entr
        ;;
    Ubuntu_22.04)
        sudo apt install -y aspell hunspell libxml2-utils chktex ruby-dev tidy python3-pip imagemagick libmagick++-dev fonts-powerline pkg-config autoconf automake python3-docutils libseccomp-dev libjansson-dev libyaml-dev libxml2-dev autojump texinfo x11-utils ttf-ancient-fonts libmagickwand-dev cpanminus libjpeg-dev libtiff-dev libgif-dev libxpm-dev libgtk-3-dev libncurses-dev libxt-dev htop unifont xfonts-terminus ttf-anonymous-pro libperl-dev libpng-dev libx11-dev libgtk2.0-dev librsvg2-dev gcc libtiff5-dev gnutls-bin libgnutls28-dev libharfbuzz-dev libharfbuzz-bin libxaw7-dev libc6-dev xaw3dg-dev zlib1g-dev libice-dev libsm-dev libxext-dev libxi-dev libxmu-dev libxmuu-dev libxrandr-dev libxtst-dev libxv-dev curl libssl-dev wget gpg libtree-sitter-dev libenchant-2-dev libwebp-dev webp libxft-dev libxft2 entr
        ;;
    Ubuntu_24.04)
        sudo apt install -y aspell hunspell libxml2-utils chktex ruby-dev tidy python3-pip imagemagick libmagick++-dev fonts-powerline pkg-config autoconf automake python3-docutils libseccomp-dev libjansson-dev libyaml-dev libxml2-dev autojump texinfo x11-utils ttf-ancient-fonts libmagickwand-dev cpanminus libjpeg-dev libtiff-dev libgif-dev libxpm-dev libgtk-3-dev libncurses5-dev libxt-dev htop unifont xfonts-terminus fonts-anonymous-pro libperl-dev libpng-dev libx11-dev libgtk2.0-dev librsvg2-dev gcc libtiff5-dev gnutls-bin libgnutls28-dev libharfbuzz-dev libharfbuzz-bin libxaw7-dev libc6-dev xaw3dg-dev zlib1g-dev libice-dev libsm-dev libxext-dev libxi-dev libxmu-dev libxmuu-dev libxrandr-dev libxtst-dev libxv-dev curl libssl-dev wget gpg libtree-sitter-dev libenchant-2-dev libwebp-dev webp libxft-dev libxft2 entr python3-libtmux terminfo
        ;;
    *)
        echo "Distribution '$DISTRO' in version '$VERSION' is not supported by this script (${DIST_VERSION})."
        exit 2
        ;;
    esac
    sudo apt autoremove -y
    sudo apt autoclean
}

gcc() {
    case "${DIST_VERSION}" in
    Ubuntu_18.04 | Ubuntu_20.04)
        sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
        sudo apt install -y gcc-10 g++-10 libgccjit0 libgccjit-10-dev libjansson4 libjansson-dev gcc-10-multilib g++-10-multilib gcc-9 g++-9
        ;;
    Ubuntu_22.04 | Ubuntu_24.4)
        sudo apt install -y gcc g++ libgccjit0 libgccjit-dev libjansson4 libjansson-dev gcc-multilib g++-multilib
        ;;
    esac
}

fish() {
    sudo apt-add-repository -y ppa:fish-shell/release-4
    sudo apt install -y fish
}

cmake() {
    cd "$HOME" || echo "Failed: cd $HOME"

    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null

    case "${DIST_VERSION}" in
    Ubuntu_18.04) echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ bionic main' | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null ;;
    Ubuntu_20.04) echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ focal main' | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null ;;
    Ubuntu_22.04) echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ jammy main' | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null ;;
    Ubuntu_24.04) echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ noble main' | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null ;;
    *)
        echo "Distribution '$DISTRO' in version '$VERSION' is not supported by this script (${DIST_VERSION})."
        exit 2
        ;;
    esac

    sudo rm /usr/share/keyrings/kitware-archive-keyring.gpg
    sudo apt install -y kitware-archive-keyring cmake
}

llvm() {
    cd "$HOME" || echo "Failed: cd $HOME"

    LLVM_VER="18"
    wget -qO- https://apt.llvm.org/llvm.sh | sudo bash -s -- ${LLVM_VER}
    rm llvm.sh
}

python_packages() {
    case "${DIST_VERSION}" in
    Ubuntu_18.04 | Ubuntu_20.04 | Ubuntu_22.04)
        python3 -m pip install --upgrade pip pygments setuptools yamllint cmake-language-server cmake-format "python-lsp-server[all]" python-lsp-isort pylsp-mypy pylsp-rope pyls-memestra python-lsp-ruff yapf jedi pylint importmagic pydocstyle cpplint grip konsave autotools-language-server libtmux argcomplete tldr basedpyright --user
        ;;
    Ubuntu_24.04)
        # TODO: This requires more work.
        python3 -m pip install --upgrade pip pygments setuptools jedi libtmux argcomplete --user
        pipx install yamllint cmake-language-server cmake-format "python-lsp-server[all]" python-lsp-isort pylsp-mypy pylsp-rope pyls-memestra yapf jedi pylint importmagic pydocstyle cpplint grip konsave autotools-language-server tldr
        ;;
    *)
        echo "Distribution '$DISTRO' in version '$VERSION' is not supported by this script (${DIST_VERSION})."
        exit 2
        ;;
    esac
}

# https://nodejs.org/en/download
nodejs() {
    cd "$HOME" || echo "Failed: cd $HOME"

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

    \. "$HOME/.nvm/nvm.sh"
    NODEJS_VER="22"
    nvm install "${NODEJS_VER}"
}

npm_packages() {
    cd "$HOME" || echo "Failed: cd $HOME"

    NPM_HOME="$HOME/tmp"
    mkdir -p "${NPM_HOME}"
    cd "${NPM_HOME}" || echo "Failed: cd ${NPM_HOME}"

    npm init --yes
    npm install --save-dev less jsonlint bash-language-server markdownlint-cli markdownlint-cli2 yaml-language-server htmlhint prettier @prettier/plugin-xml vscode-langservers-extracted npm-check-updates dockerfile-language-server-nodejs awk-language-server tree-sitter-cli prettier-plugin-awk fish-lsp

    # Add the following to "$HOME/.bashrc"
    # echo "export NODE_PATH=$HOME/tmp/node_modules" >>"$HOME/.bashrc"

    # cmdline=$"\n\nexport NODE_PATH=\$HOME/tmp/node_modules\n"
    # printf "%s" "$cmdline" >>"$HOME/.bashrc"
}

# $1 is source, $2 is the destination
create_file_symlink() {
    if [ ! -L "$2" ]; then
        echo "Creating symlink for $2..."
        ln -nsf "$1" "$2"
    else
        echo "Overwriting symlink for $2..."
        ln -nsf "$1" "$2"
    fi
    echo "...Done"
}

create_symlinks() {
    cd "$HOME" || echo "Failed: cd $HOME"

    sfname="$DOTFILES/markdown/dotmarkdownlint.json"
    dfname="$HOME/.markdownlint.json"
    create_file_symlink "$sfname" "$dfname"

    sfname="$DOTFILES/dotprettierrc"
    dfname="$HOME/.prettierrc"
    create_file_symlink "$sfname" "$dfname"

    sfname="$DOTFILES/tidyrc"
    dfname="$HOME/.tidyrc"
    create_file_symlink "$sfname" "$dfname"

    sfname="$DOTFILES/dotgitconfig"
    dfname="$HOME/.gitconfig"
    create_file_symlink "$sfname" "$dfname"

    sfname="$DOTFILES/python/pylintrc"
    dfname="$CONFIG_DIR/pylintrc"
    create_file_symlink "$sfname" "$dfname"

    sfname="$DOTFILES/python/yapf"
    dfname="$CONFIG_DIR/yapf"
    create_file_symlink "$sfname" "$dfname"

    sfname="$DOTFILES/yamllint"
    dfname="$CONFIG_DIR/yamllint"
    create_file_symlink "$sfname" "$dfname"

    sfname="$DOTFILES/bat"
    dfname="$CONFIG_DIR/bat"
    create_file_symlink "$sfname" "$dfname"

    sfname="$DOTFILES/kitty"
    dfname="$CONFIG_DIR/kitty"
    create_file_symlink "$sfname" "$dfname"

    sfname="$DOTFILES/ghostty"
    dfname="$CONFIG_DIR/ghostty"
    create_file_symlink "$sfname" "$dfname"
}

ripgrep() {
    cd "$HOME" || echo "Failed: cd $HOME"

    RG_VER="14.1.1"
    wget https://github.com/BurntSushi/ripgrep/releases/download/"${RG_VER}/ripgrep_${RG_VER}"_amd64.deb
    sudo dpkg -i ripgrep_"${RG_VER}"_amd64.deb
    rm -rf ripgrep_"${RG_VER}"_amd64.deb*

    sfname="$DOTFILES/dotripgreprc"
    dfname="$HOME/.ripgreprc"
    create_file_symlink "$sfname" "$dfname"
}

cppcheck() {
    cd "$GITHUB" || echo "Failed: cd $GITHUB"

    sudo apt install -y libpcre3-dev
    if [ ! -d cppcheck ]; then
        sudo -u swarnendu git clone git@github.com:danmar/cppcheck.git
    else
        cd cppcheck || echo "Failed: cd cppcheck"
        sudo -u swarnendu git pull
        cd ..
    fi

    cd cppcheck || echo "Failed: cd cppcheck"
    git fetch
    git checkout 2.18.0
    mkdir -p build
    cd build || echo "Failed: cd build"
    cmake ..
    cmake --build .
    make install
    cd ../..
    rm -rf cppcheck
}

# Build Universal Ctags, installing snaps seems to hurt Ubuntu performance.
uctags() {
    cd "$GITHUB" || echo "Failed: cd $GITHUB"
    CTAGS_DIR="$GITHUB/ctags"

    if [ -d "${CTAGS_DIR}" ]; then
        cd "${CTAGS_DIR}" || echo "Failed: cd ${CTAGS_DIR}"
        echo "Pulling ctags repository from GitHub..."
        sudo -u swarnendu git pull
    else
        echo "Cloning ctags repository from GitHub..."
        sudo -u swarnendu git clone https://github.com/universal-ctags/ctags.git
    fi
    echo "...Done"
    chown -R "$USER":"$USER" "${CTAGS_DIR}"

    cd "${CTAGS_DIR}" || echo "Failed: cd ${CTAGS_DIR}"
    ./autogen.sh
    ./configure --prefix="$HOME/.local/"
    make
    make install

    sfname="$DOTFILES/ctags/dotctags.d"
    dfname="$CONFIG_DIR/.ctags.d"
    create_file_symlink "$sfname" "$dfname"
}

global() {
    cd "$HOME" || echo "Failed: cd $HOME"

    GLOBAL_VER="6.6.14"
    wget http://tamacom.com/global/global-${GLOBAL_VER}.tar.gz
    tar -xzvf global-${GLOBAL_VER}.tar.gz
    cd global-${GLOBAL_VER} || exit
    ./configure --with-universal-ctags="$(which ctags)" --prefix="$HOME/.local/"
    make
    make install
    rm global-${GLOBAL_VER}.tar.gz

    sfname="$DOTFILES/global/dotglobalrc"
    dfname="$HOME/.globalrc"
    create_file_symlink "$sfname" "$dfname"

    echo "GTAGSCONF=$HOME/.globalrc" >>"$HOME"/.bashrc
    echo "GTAGSLABEL=new-ctags" >>"$HOME"/.bashrc
}

alacritty() {
    cd "$HOME" || echo "Failed: cd $HOME"

    sudo add-apt-repository ppa:aslatter/ppa -y
    sudo apt install -y alacritty

    sfname="$DOTFILES/alacritty"
    dfname="$CONFIG_DIR/alacritty"
    create_file_symlink "$sfname" "$dfname"
}

bear() {
    cd "$GITHUB" || echo "Failed: cd $GITHUB"

    sudo apt install -y libfmt-dev libspdlog-dev nlohmann-json3-dev libgrpc++-dev protobuf-compiler-grpc libssl-dev
    if [ ! -d bear ]; then
        sudo -u swarnendu git clone git@github.com:rizsotto/Bear.git bear
    else
        cd bear || echo "Failed: cd bear"
        sudo -u swarnendu git pull
        cd ..
    fi

    cd bear || echo "Failed: cd bear"
    git fetch
    git checkout 3.1.6
    mkdir -p build && cd build || echo "Failed: cd bear/build"
    cmake -DENABLE_UNIT_TESTS=OFF -DENABLE_FUNC_TESTS=OFF ..
    make all
    make install
}

powerline() {
    cd "$DOTFILES" || echo "Failed: cd $DOTFILES"

    sudo apt install -y socat

    git clone git@github.com:powerline/powerline.git
    cd powerline || exit
    git fetch
    git checkout 2.8.4
    python3 -m pip install --user --editable=.

    wget https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf
    mkdir -p "${LOCAL_DIR}"/share/fonts
    mv PowerlineSymbols.otf "${LOCAL_DIR}"/share/fonts/
    fc-cache -vf "${LOCAL_DIR}"/share/fonts/

    wget https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf
    mkdir -p "${CONFIG_DIR}"/fontconfig/conf.d
    mv 10-powerline-symbols.conf "${CONFIG_DIR}"/fontconfig/conf.d/

    cd "$DOTFILES" || echo "Failed: cd $DOTFILES"

    git clone https://github.com/powerline/fonts.git --depth=1 powerline-fonts
    cd powerline-fonts || exit
    ./install.sh
}

tmux() {
    sudo apt install -y libevent-dev entr

    cd "$GITHUB" || echo "Failed: cd $GITHUB"

    if [ -d tmux ]; then
        cd tmux || echo "Failed: cd tmux"
        echo "Pulling tmux reposiory from GitHub..."
        sudo -u swarnendu git pull
    else
        echo "Cloning tmux repository from GitHub..."
        sudo -u swarnendu git clone https://github.com/tmux/tmux
    fi
    echo "...Done"
    chown -R "$USER":"$USER" tmux

    cd tmux || echo "Failed: cd tmux"
    git fetch
    git checkout 3.5a
    ./autogen.sh
    ./configure prefix="$HOME/.local/"
    make
    make install

    sfname="$DOTFILES/tmux/tmux.conf"
    dfname="$HOME/.tmux.conf"
    create_file_symlink "$sfname" "$dfname"
}

delta() {
    cd "$HOME" || echo "Failed: cd $HOME"

    DELTA_VER="0.18.2"
    # Latest releases do not work with Ubuntu 18/20
    if [[ "${DIST_VERSION}" == Ubuntu_20.04 ]]; then
        DELTA_VER="0.14.0"
    fi

    wget https://github.com/dandavison/delta/releases/download/"${DELTA_VER}"/git-delta_"${DELTA_VER}"_amd64.deb
    sudo dpkg -i git-delta_"${DELTA_VER}"_amd64.deb
    rm git-delta_"${DELTA_VER}"_amd64.deb
}

zoxide() {
    cd "$HOME" || echo "Failed: cd $HOME"

    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

    # For bash, add this line to ~/.bashrc
    echo "eval \"$(zoxide init bash)\"" >>"$HOME/.bashrc"

    # For fish, add this line to ~/.config/fish/config.fish
    echo "zoxide init fish | source" >>"${CONFIG_DIR}/fish/config.fish"
}

bat() {
    cd "$HOME" || echo "Failed: cd $HOME"

    BAT_VER="0.25.0"
    wget https://github.com/sharkdp/bat/releases/download/v"${BAT_VER}"/bat_"${BAT_VER}"_amd64.deb
    sudo dpkg -i bat_"${BAT_VER}"_amd64.deb
    rm bat_"${BAT_VER}"_amd64.deb
}

fd() {
    cd "$HOME" || echo "Failed: cd $HOME"

    FD_VER="10.2.0"
    wget https://github.com/sharkdp/fd/releases/download/v"${FD_VER}"/fd_"${FD_VER}"_amd64.deb
    sudo dpkg -i fd_"${FD_VER}"_amd64.deb
    rm fd_"${FD_VER}"_amd64.deb
}

fzf() {
    cd "$GITHUB" || echo "Failed: cd $GITHUB"

    if [ ! -d fzf ]; then
        git clone https://github.com/junegunn/fzf.git
    else
        cd fzf || echo "Failed: cd fzf"
        sudo -u swarnendu git pull
        cd ..
    fi

    FZF_VER="v0.62.0"

    cd fzf || exit
    git fetch
    git checkout ${FZF_VER}
    bash ./install --no-zsh --key-bindings --completion --no-update-rc
}

perl_server() {
    sudo apt install -y libanyevent-perl libclass-refresh-perl libdata-dump-perl libio-aio-perl libjson-perl libmoose-perl libpadwalker-perl libscalar-list-utils-perl libcoro-perl
    cpanm Perl::LanguageServer
}

cargo_packages() {
    # Ubuntu's default Rust versions are usually old
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

    cargo install asm-lsp
    cargo install taplo-cli --features lsp
    cargo install kdlfmt
    cargo install cargo-cache
    cargo install cargo-update
    cargo install-update -a
}

install_font() {
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v"$2"/"$1.tar.xz"
    tar xf "$1.tar.xz"
    mv *.ttf "$3"
    rm "$1.tar.xz"
}

# git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git
# cd nerd-fonts/
# ./install.sh FiraCode
nerd_fonts() {
    NF_VER="3.4.0"

    fonts_dir="${LOCAL_DIR}/share/fonts"
    if [[ ! -d "$fonts_dir" ]]; then
        mkdir -p "$fonts_dir"
    fi

    declare -a FONT_NAMES=("FiraMono" "JetBrainsMono")
    for i in "${FONT_NAMES[@]}"; do
        install_font "$i" "${NF_VER}" "$fonts_dir"
    done

    fc-cache -v "${LOCAL_DIR}/fonts/."
}

# Install the binary, configure, and install plugins
zellij() {
    cd "$HOME" || echo "Failed: cd $HOME"

    ZELLIJ_VER="0.43.1"
    wget https://github.com/zellij-org/zellij/releases/download/v"${ZELLIJ_VER}"/zellij-x86_64-unknown-linux-musl.tar.gz
    tar xf zellij-x86_64-unknown-linux-musl.tar.gz
    mv zellij "${LOCAL_DIR}/bin"
    rm zellij-x86_64-unknown-linux-musl.tar.gz

    sfname="$DOTFILES/zellij"
    dfname="${CONFIG_DIR}/zellij"
    create_file_symlink "$sfname" "$dfname"

    cd "${LOCAL_DIR}/share"
    mkdir -p zellij/plugins

    wget https://github.com/dj95/zjstatus/releases/download/v0.21.0/zjstatus.wasm
    mv zjstatus.wasm zellij/plugins/.

    wget https://github.com/dj95/zjstatus/releases/download/v0.21.0/zjframes.wasm
    mv zjframes.wasm zellij/plugins/.

    wget https://github.com/b0o/zjstatus-hints/releases/download/v0.1.4/zjstatus-hints.wasm
    mv zjstatus-hints.wasm zellij/plugins/.

    wget https://github.com/cristiand391/zj-quit/releases/download/0.3.1/zj-quit.wasm
    mv zj-quit.wasm zellij/plugins/.

    wget https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm
    mv zellij_forgot.wasm zellij/plugins/.

    wget https://github.com/imsnif/monocle/releases/download/v0.100.2/monocle.wasm
    mv monocle.wasm zellij/plugins/.

    wget https://github.com/rvcas/room/releases/download/v1.2.0/room.wasm
    mv room.wasm zellij/plugins/.

    wget https://github.com/Strech/zbuffers/releases/download/v0.4.0/zbuffers.wasm
    mv zbuffers.wasm zellij/plugins/.

    wget https://github.com/Nacho114/harpoon/releases/download/v0.1.0/harpoon.wasm
    mv harpoon.wasm zellij/plugins/.

    wget https://github.com/FuriouZz/zjpane/releases/download/v0.2.0/zjpane.wasm
    mv zjpane.wasm zellij/plugins/.

    wget https://github.com/blank2121/zellij-jump-list/releases/download/Latest/zellij-jump-list.wasm
    mv zellij-jump-list.wasm zellij/plugins/.

    wget https://github.com/laperlej/zellij-choose-tree/releases/download/v0.4.2/zellij-choose-tree.wasm
    mv zellij-choose-tree.wasm zellij/plugins/.

    wget https://github.com/yaroslavborbat/zellij-bookmarks/releases/download/v0.3.0/zellij-bookmarks.wasm
    mv zellij-bookmarks.wasm zellij/plugins/.

    wget https://github.com/laperlej/zellij-sessionizer/releases/download/v0.4.3/zellij-sessionizer.wasm
    mv zellij-sessionizer.wasm zellij/plugins/.

    wget https://github.com/JoseMM2002/zellij-favs/releases/download/v0.1.8/zellij-favs.wasm
    mv zellij-favs.wasm zellij/plugins/.

    wget https://github.com/pirafrank/zellij-what-time/releases/download/0.1.1/zellij-what-time.wasm
    mv zellij-what-time.wasm zellij/plugins/.

    wget https://github.com/h1romas4/zellij-datetime/releases/download/v0.21.0/zellij-datetime.wasm
    mv zellij-datetime.wasm zellij/plugins/.
}

starship() {
    cd "$HOME" || echo "Failed: cd $HOME"

    curl -sS https://starship.rs/install.sh | sh

    sfname="$DOTFILES/starship/starship-custom.toml"
    dfname="${CONFIG_DIR}/starship.toml"
    create_file_symlink "$sfname" "$dfname"
}

local_binaries() {
    cd "$HOME" || echo "Failed: cd $HOME"

    TEXLAB_VER="5.23.1"
    wget https://github.com/latex-lsp/texlab/releases/download/v"${TEXLAB_VER}"/texlab-x86_64-linux.tar.gz
    tar xzf texlab-x86_64-linux.tar.gz
    mv texlab "$HOME/.local/bin"
    rm texlab-x86_64-linux.tar.gz

    SHELLCHECK_VER="0.11.0"
    SHELLCHECK_FILENAME="shellcheck-v${SHELLCHECK_VER}.linux.x86_64"
    wget https://github.com/koalaman/shellcheck/releases/download/v"${SHELLCHECK_VER}/${SHELLCHECK_FILENAME}.tar.xz"
    tar xf "${SHELLCHECK_FILENAME}.tar.xz"
    cd "shellcheck-v${SHELLCHECK_VER}" || echo "Failed: cd shellcheck-v${SHELLCHECK_VER}"
    mv shellcheck "${LOCAL_DIR}/bin"
    rm -rf "${SHELLCHECK_FILENAME}.tar.xz*"

    SHFMT_VER="3.12.0"
    wget https://github.com/mvdan/sh/releases/download/v"${SHFMT_VER}/shfmt_v${SHFMT_VER}"_linux_amd64
    mv shfmt_v"${SHFMT_VER}"_linux_amd64 "${LOCAL_DIR}/bin/shfmt"
    chmod a+x "${LOCAL_DIR}/bin/shfmt"

    DIFFT_VER="0.64.0"
    wget https://github.com/Wilfred/difftastic/releases/download/"${DIFFT_VER}"/difft-x86_64-unknown-linux-gnu.tar.gz
    tar xzf difft-x86_64-unknown-linux-gnu.tar.gz
    mv difft "$HOME/.local/bin/."
    rm difft-x86_64-unknown-linux-gnu.tar.gz

    MK_VER="2024-12-18"
    wget https://github.com/artempyanykh/marksman/releases/download/"${MK_VER}"/marksman-linux-x64
    mv marksman-linux-x64 "$HOME/.local/bin/marksman"
    chmod a+x "$HOME/.local/bin/marksman"

    EZA_VER="0.23.0"
    wget https://github.com/eza-community/eza/releases/download/v"${EZA_VER}"/eza_x86_64-unknown-linux-gnu.tar.gz
    tar xf eza_x86_64-unknown-linux-gnu.tar.gz
    mv eza "$HOME"/.local/bin/eza
    rm eza_x86_64-unknown-linux-gnu.tar.gz
}

# echo -e $"export LC_ALL=en_US.utf-8\nexport LANG=en_US.utf-8\nexport LANGUAGE=en_US.utf-8\nexport TERM=xterm-24bit" >>"$HOME/.bashrc"

# cmdline=$"export LC_ALL=en_US.utf-8\nexport LANG=en_US.utf-8\nexport LANGUAGE=en_US.utf-8\nexport TERM=xterm-24bit\n"
# printf "%s" "$cmdline" >>"$HOME/.bashrc"

miniconda() {
    mkdir -p ~/miniconda3
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
    rm ~/miniconda3/miniconda.sh
}

if [ ! -d "$GITHUB" ]; then
    mkdir -p "$GITHUB"
    chown -R "$USER":"$USER" "$GITHUB"
fi

# is_sudo

# if command_exists emacs; then
#     echo "emacs found"
# else
#     echo "emacs not found"
# fi

# A few functions require sudo privileges.
case $1 in
ubuntu_packages)
    ubuntu_packages
    ;;
emacs)
    emacs
    ;;
gcc)
    gcc
    ;;
llvm)
    llvm
    ;;
cmake)
    cmake
    ;;
fish)
    fish
    ;;
ripgrep)
    ripgrep
    ;;
global)
    global
    ;;
alacritty)
    alacritty
    ;;
powerline)
    powerline
    ;;
delta)
    delta
    ;;
bat)
    bat
    ;;
fd)
    fd
    ;;
perl_server)
    perl_server
    ;;
setup_emacs)
    setup_emacs
    ;;
uctags)
    uctags
    ;;
cppcheck)
    cppcheck
    ;;
bear)
    bear
    ;;
tmux)
    tmux
    ;;
python_packages)
    python_packages
    ;;
zoxide)
    zoxide
    ;;
fzf)
    fzf
    ;;
nerd_fonts)
    nerd_fonts
    ;;
create_symlinks)
    create_symlinks
    ;;
nodejs)
    nodejs
    ;;
npm_packages)
    npm_packages
    ;;
local_binaries)
    local_binaries
    ;;
zellij)
    zellij
    ;;
starship)
    starship
    ;;
miniconda)
    miniconda
    ;;
all)
    ubuntu_packages
    emacs
    gcc
    llvm
    cmake
    fish
    ripgrep
    global
    alacritty
    powerline
    delta
    bat
    fd
    perl_server
    setup_emacs
    uctags
    cppcheck
    bear
    tmux
    python_packages
    zoxide
    fzf
    nerd_fonts
    create_symlinks
    nodejs
    npm_packages
    local_binaries
    zellij
    starship
    miniconda

    sudo apt autoremove -y
    sudo apt autoclean
    ;;
*)
    usage
    ;;
esac

set +eux
