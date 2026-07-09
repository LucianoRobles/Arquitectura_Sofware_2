# ====================================================
# Trabajo Práctico - Arquitectura de Software II
# Setup automático del entorno
# ====================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Arquitectura de Software II" -ForegroundColor Cyan
Write-Host " Setup automático" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Paso 1
# Verifica que todas las herramientas necesarias
# estén instaladas antes de comenzar el despliegue.
Write-Host "[1/9] Verificando herramientas..." -ForegroundColor Yellow

docker --version | Out-Null
kubectl version --client | Out-Null
minikube version | Out-Null

Write-Host "OK" -ForegroundColor Green

# Paso 2
# Iniciamos (o reutilizamos) el clúster local de Minikube.

Write-Host "[2/9] Iniciando Minikube..." -ForegroundColor Yellow

minikube start --driver=docker

Write-Host "OK" -ForegroundColor Green

# Paso 3
# Esperamos hasta que Kubernetes responda correctamente antes de continuar con el resto del proceso.

Write-Host "[3/9] Esperando que Kubernetes esté listo..." -ForegroundColor Yellow

do {

    Start-Sleep -Seconds 5

    try {
        kubectl get nodes | Out-Null
        $ready = $true
    }
    catch {
        $ready = $false
    }

} until ($ready)

Write-Host "OK" -ForegroundColor Green

# Paso 4
# Habilitamos el addon de Ingress para exponer la aplicación mediante una única URL.

Write-Host "[4/9] Habilitando Ingress..." -ForegroundColor Yellow

minikube addons enable ingress

Write-Host "OK" -ForegroundColor Green

# Paso 5
# Esperamos a que el controlador de Ingress quede completamente operativo.

Write-Host "[5/9] Esperando Ingress Controller..." -ForegroundColor Yellow

kubectl wait `
    --namespace ingress-nginx `
    --for=condition=Ready `
    pod `
    --selector=app.kubernetes.io/component=controller `
    --timeout=300s

Write-Host "OK" -ForegroundColor Green

# Paso 6
# Construye la imagen Docker del backend e importa la imagen directamente en Minikube.

Write-Host "[6/9] Construyendo Backend..." -ForegroundColor Yellow

minikube image build `
    -t tasks-backend:local `
    ./app/backend

Write-Host "OK" -ForegroundColor Green

# Paso 7
# Construye la imagen Docker del frontend e importa la imagen directamente en Minikube.

Write-Host "[7/9] Construyendo Frontend..." -ForegroundColor Yellow

minikube image build `
    -t tasks-frontend:local `
    ./app/frontend

Write-Host "OK" -ForegroundColor Green

# Paso 8
# Despliega todos los recursos definidos en la carpeta manifests (Deployments, Services, StatefulSet, ConfigMaps, Secrets e Ingress).

Write-Host "[8/9] Aplicando manifiestos..." -ForegroundColor Yellow

kubectl apply -f manifests/

Write-Host "OK" -ForegroundColor Green

# Paso 9
# Esperamos hasta que todos los Pods del namespace se encuentren en estado Ready.

Write-Host "[9/9] Esperando Pods..." -ForegroundColor Yellow

kubectl wait `
    --for=condition=Ready `
    pod `
    --all `
    -n arqsw2 `
    --timeout=300s

Write-Host "OK" -ForegroundColor Green
# Paso 10
# Inicia Minikube Tunnel para permitir el acceso al Ingress desde el navegador.
# Este proceso permanece en ejecución y la ventana debe mantenerse abierta mientras se utilice la aplicación.
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host " El entorno fue desplegado correctamente." -ForegroundColor Green
Write-Host ""
Write-Host " La aplicación estará disponible en:"
Write-Host " http://app.local" -ForegroundColor Yellow
Write-Host ""
Write-Host " Iniciando Minikube Tunnel..." -ForegroundColor Cyan
Write-Host " No cierre esta ventana mientras utilice la aplicación."
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

minikube tunnel