$u = "http://localhost:8080"
$j = "application/json"

$datos = @{ email = "prueba@correo.com"; password = "clave12345" } | ConvertTo-Json
$login = Invoke-RestMethod "$u/login" -Method Post -ContentType $j -Body $datos
$h = @{ Authorization = "Bearer $($login.token)" }

$t = @{ title = "Escríbeme un poema de amor"; details = "" } | ConvertTo-Json
$nueva = Invoke-RestMethod "$u/tasks" -Method Post -ContentType $j -Headers $h -Body $t
Write-Host "Tarea creada con id: $($nueva.id)"

$lista = Invoke-RestMethod "$u/tasks" -Headers $h
foreach ($tarea in $lista.tasks) {
  Write-Host ""
  Write-Host "TAREA: $($tarea.title)"
  foreach ($p in $tarea.steps) {
    Write-Host "  - $($p.title) ($($p.minutes) min)"
  }
}