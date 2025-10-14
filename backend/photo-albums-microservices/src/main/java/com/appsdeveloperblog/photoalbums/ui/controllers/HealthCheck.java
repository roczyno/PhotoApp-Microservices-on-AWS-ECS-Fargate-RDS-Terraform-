package com.appsdeveloperblog.photoalbums.ui.controllers;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/photo/healthcheck")
public class HealthCheck {

	@GetMapping
	public String healthCheck() {
		return "OK from photo albums microservice";
	}
}
