foreach ($1 in (Get-MsolAccountSku)){
write $1.ServiceStatus.ServicePlan.servicename
}


(Get-MsolAccountSku).ServiceStatus