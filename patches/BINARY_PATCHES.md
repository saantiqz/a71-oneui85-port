# Binary patches (file offset: original bytes -> new bytes)

- system/bin/vold @ 0x94d60: 290100b4 -> 09000014
  Branch past the auth-token rejection in VoldNativeService::unlockCeStorage, so the PIN unlocks storage after a framework restart.
- system/lib64/libstagefright.so @ 0xed2a0: 02408052 -> e21f8052
  fread count 512 -> 255 (fixes a FORTIFY abort in ACodec on this platform).
