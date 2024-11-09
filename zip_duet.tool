#!/bin/bash

abort() {
  echo "ERROR: $1!"
  exit 1
}

  efidirs=(
    "EFI/BOOT"
    "EFI/OC/ACPI"
    "EFI/OC/Drivers"
    "EFI/OC/Kexts"
    "EFI/OC/Tools"
    "EFI/OC/Resources/Audio"
    "EFI/OC/Resources/Font"
    "EFI/OC/Resources/Image"
    "EFI/OC/Resources/Label"
    )

  # Switch to parent architecture directory (i.e. Build/X64 -> Build).
  local dstdir
  dstdir="$(pwd)/tmp"
  pushd .. || exit 1

  for arch in "${ARCHS[@]}"; do
    for dir in "${efidirs[@]}"; do
      mkdir -p "${dstdir}/${arch}/${dir}" || exit 1
    done

 
  utilScpts=(
    "LegacyBoot"
    )
  for utilScpt in "${utilScpts[@]}"; do
    cp -r "${selfdir}/Utilities/${utilScpt}" "${dstdir}/Utilities"/ || exit 1
  done

  # Copy OpenDuetPkg booter.
  for arch in "${ARCHS[@]}"; do
    local tgt
    local booter
    local booter_blockio
    tgt="$(basename "$(pwd)")"
    booter="$(pwd)/../../OpenDuetPkg/${tgt}/${arch}/boot"
    booter_blockio="$(pwd)/../../OpenDuetPkg/${tgt}/${arch}/boot-blockio"

    if [ -f "${booter}" ]; then
      echo "Copying OpenDuetPkg boot file from ${booter}..."
      cp "${booter}" "${dstdir}/Utilities/LegacyBoot/boot${arch}" || exit 1
    else
      echo "Failed to find OpenDuetPkg at ${booter}!"
    fi
    if [ -f "${booter_blockio}" ]; then
      echo "Copying OpenDuetPkg BlockIO boot file from ${booter_blockio}..."
      cp "${booter_blockio}" "${dstdir}/Utilities/LegacyBoot/boot${arch}-blockio" || exit 1
    else
      echo "Failed to find OpenDuetPkg BlockIO at ${booter_blockio}!"
    fi
  done

  for util in "${utils[@]}"; do
    dest="${dstdir}/Utilities/${util}"
    mkdir -p "${dest}" || exit 1
    bin="${selfdir}/Utilities/${util}/${util}"
    cp "${bin}" "${dest}" || exit 1
    if [ -f "${bin}.exe" ]; then
      cp "${bin}.exe" "${dest}" || exit 1
    fi
    if [ -f "${bin}.linux" ]; then
      cp "${bin}.linux" "${dest}" || exit 1
    fi
  done
  # additional docs for macserial.
  cp "${selfdir}/Utilities/macserial/FORMAT.md" "${dstdir}/Utilities/macserial"/ || exit 1
  cp "${selfdir}/Utilities/macserial/README.md" "${dstdir}/Utilities/macserial"/ || exit 1
  # additional docs for ocvalidate.
  cp "${selfdir}/Utilities/ocvalidate/README.md" "${dstdir}/Utilities/ocvalidate"/ || exit 1

  pushd "${dstdir}" || exit 1
  zip -qr -FS ../"OpenCore-${ver}-${2}.zip" ./* || exit 1
  popd || exit 1
  rm -rf "${dstdir}" || exit 1

  popd || exit 1
  popd || exit 1
}

cd "$(dirname "$0")" || exit 1
if [ "$ARCHS" = "" ]; then
  ARCHS=(X64 IA32)
  export ARCHS
fi
SELFPKG=OpenCorePkg
NO_ARCHIVES=0
DISCARD_SUBMODULES=OpenCorePkg

export SELFPKG
export NO_ARCHIVES
export DISCARD_SUBMODULES

src=$(curl -LfsS https://raw.githubusercontent.com/acidanthera/ocbuild/master/efibuild.sh) && eval "$src" || exit 1

