#!/usr/bin/env bash

# Capture details of running host
SOFTWARE=(make bash python3 pip3 dafny)

version() {
  vc="$1 ${2:-"--version"}"
  if ! command -v "$1" 2>&1 >/dev/null; then
    echo "not installed"
  else
    v=$($vc 2>/dev/null | perl -pe 'if(($v)=/([0-9]+([.][0-9]+)+)/){print"$v\n";exit}$_=""')
    if [ -z "$v" ]; then v="?"; fi
    echo "$v"
  fi
}

echo "HARDWARE"
if echo "$OSTYPE" | grep -qi 'linux' ; then
  proc=$(lscpu | grep 'Model name' | cut -f 2 -d ":" | awk '{$1=$1}1')
  echo "  OS: $(lsb_release -as 2>/dev/null | sed -n 2,3p | tac | tr '\n' ' ')"
  echo "  Kernel: $(uname -s) $(uname -r)"
  echo "  Architecture: $(uname -m)"
  echo "  Processor: ${proc:-"unknown"}"
  echo "  Cores: $(lscpu | grep -E '^Core\(' | awk '{print $(NF)}')"
  echo "  Total memory: $(awk '/MemTotal/ { printf "%.3f \n", $2/1024/1024 }' /proc/meminfo) GB"
elif echo "$OSTYPE" | grep -qi 'darwin' ; then
  echo "  OS: $(sw_vers -productName)"
  echo "  Version: $(sw_vers -productVersion)"
  echo "  Build: $(sw_vers -buildVersion)"
  echo "  Architecture: $(uname -m)"
  echo "  CPU Brand: $(sysctl -n machdep.cpu.brand_string)"
  echo "  Cores: $(sysctl -n hw.ncpu)"
  echo "  Memory: $(( $(sysctl -n hw.memsize) / $((1024 ** 3)))) GB"
else
  echo "Operating system: $OSTYPE"
fi
echo "SOFTWARE"
for sw in "${SOFTWARE[@]}"; do
  echo "  $sw: $(version "$sw")";
done