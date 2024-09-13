# Define o caminho do arquivo de saída na pasta atual
$outputFile = Join-Path -Path $PSScriptRoot -ChildPath "DescricaoOLX.txt"

# Coleta informações do Processador
$cpu = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name

# Coleta informações da Placa de Vídeo
$gpu = Get-WmiObject Win32_VideoController | Select-Object -ExpandProperty Name
$gpuMemory = [math]::Round((Get-WmiObject Win32_VideoController | Select-Object -ExpandProperty AdapterRAM) / 1MB)

# Coleta informações da Memória RAM
$ram = (Get-WmiObject Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB
$ram = [math]::Round($ram, 2)

# Coleta informações do Disco (Modelo e Espaço Total)
$discos = Get-WmiObject Win32_DiskDrive | Select-Object Model, Size
$discosInfo = ""
foreach ($disco in $discos) {
    $tamanhoGB = [math]::Round($disco.Size / 1GB, 2)
    $discosInfo += "$($disco.Model) - $tamanhoGB GB`n"
}

# Coleta informações do Sistema Operacional
$os = Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty Caption
$osVersion = Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty Version

# Coleta informações adicionais úteis (Nome do computador)
$computerName = $env:COMPUTERNAME

# Monta o texto do arquivo para a venda
$conteudo = @"
INFORMAÇÕES DO COMPUTADOR PARA VENDA

Nome do Computador: $computerName

PROCESSADOR:
Modelo: $cpu

PLACA DE VÍDEO:
Modelo: $gpu
Memória: $gpuMemory MB

MEMÓRIA RAM:
Quantidade: $ram GB

DISCO RÍGIDO:
$discosInfo

SISTEMA OPERACIONAL:
Versão: $os
Build: $osVersion

OBSERVAÇÕES:
Computador em ótimo estado, pronto para uso! Ideal para trabalho, estudo e lazer. Para mais informações ou para marcar uma visita, entre em contato.

"@

# Salva o conteúdo no arquivo de saída com o encoding UTF-8 BOM para suportar acentuações corretamente
$conteudo | Out-File -FilePath $outputFile -Encoding utf8BOM

Write-Output "Informações salvas com sucesso em $outputFile"
