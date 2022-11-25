#!/bin/zsh
# vim: set ft=zsh:

_PECO_FIND_MAXDEPTH=3
_PECO_LAYOUT="top-down"

## set variable `cur` `left` `right`
## `cur` = curent word
## `left` = left side string
## `right` = right side string
function __init_line {
  local line="$2" pos="$1" i=0
  local _c _left _right _cur
  i=$((pos - 1))
  while (( i > 0 )); do
    _c="${line:$i:1}"
    # printf "#### %2d: '%s'\n" $i "$_c"
    if [[ "$_c" = [[:space:]:=@] ]]; then
      _left="${line:0:$((i+1))}"
      _right="${line:$pos}"
      _cur="${line:$((i+1)):$(( pos - i - 1))}"
      break
    fi
    i=$(( i - 1 ))
  done
  if (( i == 0 )); then
    _left=""
    _right="${line:$pos}"
    _cur="${line:0:$pos}"
  fi
  if [[ -n "$_right" ]]; then
    if [[ "$_right" = *[[:space:]]* ]]; then
      for (( i=0; i < ${#_right}; i++)); do
        _c="${_right:$i:1}"
        if [[ "$_c" = [[:space:]] ]]; then
          _cur="${_cur}${_right:0:$i}"
          _right="${_right:$i}"
          break
        fi
      done
    else
      _cur="${_cur}${_right}"
      _right=""
    fi
  fi
  eval cur=\"$_cur\" left=\"$_left\" right=\"$_right\"
}

function _peco_find_dir {
  local cur left right
  __init_line ${CURSOR} "${BUFFER}" || return
  local _dir="$(eval echo ${cur:-.})" _query="" _result=""
  if [ ! -d "${_dir}" ]; then
    _query="${_dir##*/}"
    _dir="${_dir%/*}"
  elif [[ "$_dir" != /* ]]; then
    if [[ "$_dir" = */* ]]; then
      _query="${_dir##*/}"
      _dir="${_dir%/*}"
    else
      _query="$cur"
      _dir=""
    fi
  fi

  local peco_opts=(--layout ${_PECO_LAYOUT} --query "${_query}" --prompt "Directory: $(realpath ${_dir:-.})>'")
  if [[ "$cur" = .* ]]; then
    _result=$(fd . $_dir -t d -d ${_PECO_FIND_MAXDEPTH} | peco "${peco_opts[@]}")
  else
    _result=$(fd . $_dir -t d -d ${_PECO_FIND_MAXDEPTH} | sed 's|^\./||' | peco "${peco_opts[@]}")
  fi
  left="${left}${_result}"
  BUFFER="${left}${right}"
  CURSOR=${#left}
}

function _peco_find_file {
  local cur left right
  __init_line ${CURSOR} "${BUFFER}" || return

  local _dir="" _query="$(eval echo $cur)"  _result="" fd_opts=()
  if [[ "$cur" = */* ]]; then
    _query="${cur##*/}"
    _dir="${cur%/*}"
  fi
  if [[ -n "$_query" ]]; then
    if [[ "$_query" = *\** ]]; then
      _fd_pattern="-g $_query"
    else
      _fd_pattern="-g '*$_query*'"
    fi
  fi
  local peco_opts=(--layout ${_PECO_LAYOUT} --prompt "File($_fd_pattern) in: $(realpath ${_dir:-.})>")
  if [[ "$cur" = .* ]]; then
    _result=$(fd $_fd_pattern $_dir -t f -d ${_PECO_FIND_MAXDEPTH} | peco "${peco_opts[@]}" | xargs)
  else
    _result=$(fd $_fd_pattern $_dir -t f -d ${_PECO_FIND_MAXDEPTH} | sed 's|^\./||' | peco "${peco_opts[@]}" | xargs)
  fi
  left="${left}${_result}"
  BUFFER="${left}${right}"
  CURSOR=${#left}
}

zle -N _peco_find_file
zle -N _peco_find_dir
bindkey '^g^d' _peco_find_dir
bindkey '^g^f' _peco_find_file

