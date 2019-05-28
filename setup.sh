
source ./tools/ask.sh
source ./tools/ensure_symlink.sh

# TODO:
# osx - mas (mac app store CLI: brew)
# osx - set icon
# iterm - set colour scheme
# terminal - raise bug on broken colours
# shell - tldr

# Identify the operating system.
un=$(uname -a)
os="unknown"
if [[ "$un" =~ [Dd]arwin ]]; then
    echo "Operating System: OSX"
    os="osx"
elif [[ "$un" =~ [Uu]buntu ]]; then
    echo "Operating System: Ubuntu"
    os="ubuntu"
else
    echo "Operating System: Unknown"
    exit 1
fi

# Setup any package manager required.
if [[ "$os" == "osx" ]]; then
    echo "$os: Checking for brew..."
    which -s brew
    if [[ $? != 0 ]] ; then
        if ask "$os: HomeBrew is not installed. Install it?" Y; then
            echo "$os: Installing HomeBrew..."
            /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        fi    
    fi
    if ask "$os: Update HomeBrew?" Y; then
        echo "$os: Updating brew..."
        brew update
    fi
elif [[ "$os" == "ubuntu" ]]; then
    if ask "$os: update apt?" Y; then
        echo "$os: Updating apt..."
        sudo apt-get update -y
    fi
fi

# Install MacOSX Applications.
if [[ "$os" == "osx" ]]; then
    if ask "$os: Install Applications (vlc)?" Y; then
        brew install caskroom/cask/brew-cask
        brew cask install google-chrome
        brew cask install 1password
        brew cask install dropbox
        brew cask install sourcetree
        brew cask install vlc
        brew cask install virtualbox && brew cask install vagrant

        # Programming.
        brew cask install iterm2
        brew cask install visual-studio-code

        # Communication.
        brew cask install whatsapp
        brew cask install slack

        # The 'Hack' font.
        brew tap caskroom/fonts
        brew cask install font-hack
        
        # TODO: move to its own section and have it's own profile.
        # Docker and associated tools.
        brew cask install docker
        brew install kubectl
        brew cask install minikube

        # Muzak stuff.
        brew cask install spotmenu

        # Utilities.
        brew cask install spectacle
    fi
fi

# Install Linux apps.
if [[ "$os" == "osx" ]]; then
    if ask "$os: Install Linux CLI apps (telnet, tree, wget, etc)?" Y; then
        brew install telnet wget tree
    fi
fi

# Move to zsh.
echo "$os: checking shell..."
if [[ "$SHELL" != "/bin/zsh" ]]; then
    if ask "$os: Shell is '$SHELL', change to zsh?" Y; then
        if [[ "$os" == "osx" ]]; then
            echo "$os: Installing zsh..."
            brew install zsh zsh-completions
            # Make sure the installed zsh path is allowed in the list of shells.
            echo "$(which zsh)" >> sudo tee -a /etc/shells
            chsh -s "$(which zsh)"
        elif [[ "$os" == "ubuntu" ]]; then
            echo "$os: Installing zsh..."
            apt-get install -y zsh zsh-completions
            chsh -s "$(which zsh)"
        fi
    fi
fi

# Check the shell, and make sure that we are sourcing the .profile file.
if ask "$os: Add .profile to bash/zsh?" Y; then
	ensure_symlink "$(pwd)/profile.sh" "$HOME/.profile.sh"
	ensure_symlink "$(pwd)/profile" "$HOME/.profile"
    echo "" >> ~/.bashrc
    echo "# Load dotfiles shell configuration." >> ~/.bashrc
    echo "source ~/.profile.sh" >> ~/.bashrc
    echo "" >> ~/.zshrc
    echo "# Load dotfiles shell configuration." >> ~/.zshrc
    echo "source ~/.profile.sh" >> ~/.zshrc
    if [[ "$SHELL" =~ bash ]]; then
        source ~/.bashrc
    elif [[ "$SHELL" =~ zsh ]]; then 
        source ~/.zshrc
    fi
fi

if ask "$os: Install/Update/Configure Vim?" Y; then
    # I use ~/tmp for a lot of vim temp stuff...
    mkdir ~/tmp

    if [[ "$os" == "osx" ]]; then
        echo "$os: Installing vim..."
        brew install vim
    elif [[ "$os" == "ubuntu" ]]; then
        echo "$os: Installing vim..."
        apt-get update && apt-get install vim
    fi
    
    # Install Vundle.
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

    # Use our dotfiles for vimrc and vim spell.
    ensure_symlink "$(pwd)/vim/vim-spell-en.utf-8.add" "$HOME/.vim-spell-en.utf-8.add"
    ensure_symlink "$(pwd)/vim/vimrc" "$HOME/.vimrc"
fi

# Configure Git.
if ask "$os: Configure mindmelting user for Git?" Y; then
    echo "$os: Configuring Git for mindmelting"
    git config --global user.name "Lawrence Hunt"
    git config --global user.email "lawrence.hunt@gmail.com"
fi

# If asdf is not installed, install it.
echo "$os: Checking for asdf..."
asdf_installed=$(command -v asdf)
if [[ ${asdf_installed} != 0 ]] ; then
    if [[ "$os" == "osx" ]]; then
        if ask "$os: asdf is not installed. Install it?" Y; then
            echo "$os: Installing asdf..."
            brew install asdf
        fi
    fi   
else
    echo "$os: asdf is installed..."
fi

# Configure Terraform.
if ask "$os: Setup Terraform and Terraform Lint?" Y; then
    if [[ "$os" == "osx" ]]; then
        brew install terraform
        brew tap wata727/tflint
        brew install tflint
    elif [[ "$os" == "ubuntu" ]]; then
        echo "$os: TODO"
    fi
fi

# Setup Java.
if ask "$os: Setup Java 8?" Y; then
    if [[ "$os" == "osx" ]]; then
        # Note that Java 8 is not the latest version, but some tools like the
        # Android SDK don't support version 9 at the time of writing. So install
        # Java 8 by preference.
        brew cask reinstall AdoptOpenJDK/homebrew-openjdk/adoptopenjdk
    elif [[ "$os" == "ubuntu" ]]; then
        echo "$os: TODO"
    fi
fi

# Setup Android.
android_version="28"
if ask "$os: Setup Android v${android_version}?" Y; then
    if [[ "$os" == "osx" ]]; then
        brew install gradle

        # Install the Android SDK and HAXM.
        brew cask install android-sdk
        brew cask install intel-haxm

        # Now install the appropriate SDKs components for the given Android version.
        sdkmanager "platform-tools" "platforms;android-${android_version}" "extras;intel;Hardware_Accelerated_Execution_Manager" "build-tools;${android_version}.0.0" "system-images;android-${android_version};google_apis;x86" "emulator"

        # Finally, create an emulator for the given Android version.
        avdmanager create avd -memory 768 -n Android28Emulator -k "system-images;android-${android_version};google_apis;x86"

        # We should *not* have an 'emulator' symlink, as we add:
        #   /usr/local/share/android-sdk/emulator/
        # to our path. Having the link causes 'missing binary' issues. So remove it.
        rm /usr/local/share/android-sdk/emulator/emulator
    elif [[ "$os" == "ubuntu" ]]; then
        echo "$os: TODO"
    fi
fi

# Setup ag.
if ask "$os: Install/Configure The Silver Searcher?" Y; then
    if [[ "$os" == "osx" ]]; then
        brew install the_silver_searcher
    elif [[ "$os" == "ubuntu" ]]; then
        echo "$os: Updating tmux..."
        apt-get install -y silversearcher-ag
    fi
fi

if ask "$os: Setup AWS/GCP/Azure/Alicloud CLIs?" Y; then
    if [[ "$os" == "osx" ]]; then
        brew install awscli
        brew install azure-cli
    elif [[ "$os" == "ubuntu" ]]; then
        pip3 install awscli --upgrade --user

        # Install az cli dependencies, Microsoft's key, thb binary.
        sudo apt-get install curl apt-transport-https lsb-release gpg
        curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
            gpg --dearmor | \
            sudo tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null
        AZ_REPO=$(lsb_release -cs)
        echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
            sudo tee /etc/apt/sources.list.d/azure-cli.list
        sudo apt-get update
        sudo apt-get install azure-cli
    fi
fi

# Many changes (such as chsh) need a restart, offer it now,
if ask "$os: Some changes may require a restart - restart now?" Y; then
    if [[ "$os" == "osx" ]]; then
        echo "$os: Restarting..."
        sudo shutdown -r now
    elif [[ "$os" == "ubuntu" ]]; then
        echo "$os: Restarting..."
        echo "TODO"
    fi
fi



exit;

# Re-attach to user namespace is needed to get the system clipboard setup.
brew install reattach-to-user-namespace
brew install bash-completion

# Not sure if we want this here, but here's some zsh completion...
mkdir -p ~/.zsh/completion
curl -L https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/zsh/_docker > ~/.zsh/completion/_docker
curl -L https://raw.githubusercontent.com/docker/machine/v0.13.0/contrib/completion/zsh/_docker-machine > ~/.zsh/completion/_docker-machine
curl -L https://raw.githubusercontent.com/docker/compose/1.17.0/contrib/completion/zsh/_docker-compose > ~/.zsh/completion/_docker-compose

# Install linters and related tools. These are used by ALE in Vim.

# HTML linting.
brew install tidy-html5

# Setup hub.
brew install hub
