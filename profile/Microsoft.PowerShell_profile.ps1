# Remove built-in ls alias so our function wins
if (Get-Alias ls -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls
}

function ls { eza -al --icons --color=always --group-directories-first @args }
function la { eza -a  --icons --color=always --group-directories-first @args }
function ll { eza -l  --icons --color=always --group-directories-first @args }
function lt { eza -aT --icons --color=always --group-directories-first @args }

Invoke-Expression (&starship init powershell)
