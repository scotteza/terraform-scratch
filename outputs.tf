 output "current_region" {
   value = data.aws_region.current_region
 }
//
// output "ssh" {
//   value = {
//     "ldap" = module.ecs-spike.ssh_login
//   }
// }


