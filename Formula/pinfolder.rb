class Pinfolder < Formula
  desc "Pin files & folders on macOS: menu bar, top of folder, or Finder sidebar"
  homepage "https://sai-na.github.io/PinFolder/"
  url "https://github.com/sai-na/PinFolder/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "93db26550ba9d41840d95a4b007b52d70c4c93ac373710883b8c9afb050099c2"
  license "MIT"

  depends_on :macos

  def install
    system "make", "app"
    prefix.install "PinFolder.app"
    bin.install "pinsidebar"

    # stage the Finder Quick Action bundles for pinfolder-setup to install
    system "python3", "make-workflows.py", pkgshare/"workflows"

    (bin/"pinfolder-setup").write <<~EOS
      #!/bin/zsh
      # PinFolder setup helper.
      #   pinfolder-setup             install: app -> /Applications + register Quick Actions
      #   pinfolder-setup uninstall   remove the app and the three Quick Actions
      set -e
      if [ "$1" = "uninstall" ]; then
        osascript -e 'quit app "PinFolder"' 2>/dev/null || true
        rm -rf "/Applications/PinFolder.app"
        rm -rf "$HOME/Library/Services/📌 Pin.workflow" \\
               "$HOME/Library/Services/📌 Pin on Top.workflow" \\
               "$HOME/Library/Services/📌 Pin to Sidebar.workflow"
        /System/Library/CoreServices/pbs -update 2>/dev/null || true
        echo "Removed the app and the three Quick Actions."
        echo "Kept (delete them yourself if you want them gone):"
        echo "  ~/.pinned-folders            your pins list"
        echo "  ' 📌 ' shortcut symlinks     from Pin on Top, in their folders"
        echo "  sidebar Favourites entries   right-click -> Remove from Sidebar"
        echo "Finish with: brew uninstall pinfolder"
        exit 0
      fi
      osascript -e 'quit app "PinFolder"' 2>/dev/null || true
      rm -rf "/Applications/PinFolder.app"
      cp -R "#{opt_prefix}/PinFolder.app" /Applications/
      open /Applications/PinFolder.app
      open "#{opt_pkgshare}/workflows/📌 Pin.workflow"
      open "#{opt_pkgshare}/workflows/📌 Pin on Top.workflow"
      open "#{opt_pkgshare}/workflows/📌 Pin to Sidebar.workflow"
      echo ""
      echo "A 📌 appeared in the menu bar, and macOS is showing three install"
      echo "prompts — click Install on each. Then right-click any file or folder"
      echo "in Finder → Quick Actions → 📌 Pin / 📌 Pin on Top / 📌 Pin to Sidebar."
    EOS
    chmod 0755, bin/"pinfolder-setup"
  end

  def caveats
    <<~EOS
      To finish setting up (copies the app to /Applications and registers the
      Finder Quick Actions — macOS will ask you to confirm each one), run:

        pinfolder-setup

      To uninstall later:

        pinfolder-setup uninstall && brew uninstall pinfolder
    EOS
  end

  test do
    # pinsidebar with no arguments prints usage and exits 2
    assert_match "usage:", shell_output("#{bin}/pinsidebar 2>&1", 2)
    assert_predicate prefix/"PinFolder.app/Contents/MacOS/PinFolder", :executable?
  end
end
