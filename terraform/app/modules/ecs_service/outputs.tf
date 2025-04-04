output "security_group_id" {
  value       = aws_security_group.this.id
  description = "The ID of the security group for the ECS service"
}

output "service" {
  value = {
    id   = aws_ecs_service.this.id
    name = aws_ecs_service.this.name
  }
  description = "Essential attributes of the ECS service"
}

output "task_definition" {
  value       = aws_ecs_task_definition.this.family
  description = "Essential attributes of the ECS task definition"
}
