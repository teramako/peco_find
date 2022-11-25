#!/bin/zsh
# vim: set ft=zsh:

_PECO_FIND_MAXDEPTH=5
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

  local peco_opts=(--layout ${_PECO_LAYOUT} --query "${_query}" --prompt "Directory: $(realpath ${_dir:-.})> ")
  local fd_opts=(--type d --maxdepth ${_PECO_FIND_MAXDEPTH})
  _result=$(fd "${fd_opts[@]}" . ${_dir:-} | peco "${peco_opts[@]}")
  left="${left}${_result}"
  BUFFER="${left}${right}"
  CURSOR=${#left}
  zle reset-prompt
}

function _peco_find_file {
  local cur left right
  __init_line ${CURSOR} "${BUFFER}" || return

  local _dir="" _query="$(eval echo $cur)"  _result="" fd_opts=()
  if [[ "$_query" = */* ]]; then
    if [[ -d "$_query" ]]; then
      _dir="$_query"
      _query=""
    else
      _dir="${_query%/*}"
      _query="${_query##*/}"
    fi
  elif [[ -d "$_query" ]]; then
    _dir="$_query"
    _query=""
  fi
  local peco_opts=(--layout ${_PECO_LAYOUT} --query "${_query}" --prompt "File in: $(realpath ${_dir:-.})>")
  fd_opts+=(--type f --maxdepth ${_PECO_FIND_MAXDEPTH})
  _result=$(fd "${fd_opts[@]}" . ${_dir:-} | peco "${peco_opts[@]}" | xargs)

  left="${left}${_result}"
  BUFFER="${left}${right}"
  CURSOR=${#left}
  zle reset-prompt
}

zle -N _peco_find_file
zle -N _peco_find_dir
bindkey '^g^d' _peco_find_dir
bindkey '^g^f' _peco_find_file

