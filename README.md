NixOS on Hyperkit
=================

Scripts and tools for building and running NixOS VMs using Hyperkit on macOS.


Build a suitable ISO for automated installation
-----------------------------------------------

1. Download a minimal installation CD from the [NixOS download
   page](https://nixos.org/nixos/download.html) saving it in the `isos` directory.

  ```
  # https://d3g5gsiof5omrk.cloudfront.net/nixos/18.03/nixos-18.03.132687.14c248a4ab7/nixos-minimal-18.03.132687.14c248a4ab7-x86_64-linux.iso
  mkdir isos/nixos-minimal-18.03.132687.14c248a4ab7-x86_64-linux.iso
  curl -Lo nixos-minimal-18.03.132687.14c248a4ab7-x86_64-linux.iso/raw.iso https://d3g5gsiof5omrk.cloudfront.net/nixos/18.03/nixos-18.03.132687.14c248a4ab7/nixos-minimal-18.03.132687.14c248a4ab7-x86_64-linux.iso
  ```

2. Start a VM using the downloaded installation CD.
  
  ```
  make livecd ISO=isos/nixos-minimal-18.03.132687.14c248a4ab7-x86_64-linux.iso
  ```

3. In the VM, start the SSH dameon and set a root password.
  
  ```
  systemctl start sshd
  passwd
  ```

4. Find the IP address of the VM and copy `iso.nix` to the VM.

  ```
  bin/scp iso.nix root@192.168.65.20:iso.nix
  ```

5. Remount the tmpfs used by the Nix store with more space to ensure the ISO
   can build.

  ```
  mount -o remount,size=2G /nix/.rw-store
  ```

6. Build the ISO.

  ```
  nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix
  ```

7. Copy the ISO from the VM to the `isos` directory.

  ```
  mkdir isos/nixos-custom-18.03.132628.a381b789984-x86_64-linux.iso
  bin/scp root@192.168.65.20:result/iso/nixos-custom-18.03.132628.a381b789984-x86_64-linux.iso \
    isos/nixos-custom-18.03.132628.a381b789984-x86_64-linux.iso/raw.iso
  ```
