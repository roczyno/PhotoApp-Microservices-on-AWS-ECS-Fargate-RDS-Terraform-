package com.appsdeveloperblog.photoapp.api.users.ui.controllers;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/users/healthcheck")
public class HealthCheck {


	@GetMapping
	public String healthCheck() {
		return "OK from users microservice";
	}
}
