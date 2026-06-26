      ============================================================
       tiny11 VM — POST-SETUP STEPS
      ============================================================

      STEP 1 — Open virt-manager, double-click tiny11, complete Windows install.

      STEP 2 — Shared folder
        Host path : /var/lib/libvirt/vm-share
        Inside Windows:
          1. Install WinFSP        : https://winfsp.dev/rel/
          2. Install virtio-win guest tools
          3. Map \\vmshare\ in Windows Explorer

      STEP 3 — Clipboard (copy/paste between host and VM)
        Install SPICE guest tools inside Windows:
          https://www.spice-space.org/download.html
          → Windows Binaries → spice-guest-tools
        Clipboard sharing activates automatically once installed.

      ============================================================

      \To get OneDrive working, you usually need to flip a specific "switch" in the Windows Registry that Tiny11 turns off to save background cycles.
The Registry Fix

    In your Tiny11 VM, press Win + R, type regedit, and hit Enter.

    Navigate to the following path:

        HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\OneDrive

    Look for a value named DisableFileSyncNGSC.

    Double-click it and change the Value data from 1 to 0.

        Note: If you don't see this key or the OneDrive folder at all, you may need to download the OneDrive standalone installer from Microsoft first.

    Restart the VM.