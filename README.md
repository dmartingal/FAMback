# 🏃‍♂️ Microservicio de Gestión de Resultados de Atletismo

Este proyecto es un **microservicio desarrollado con Spring Boot** que permite gestionar atletas, clubes y resultados de competiciones de atletismo.  
Su propósito es automatizar la inserción de resultados a partir de archivos CSV generados mediante IA, y mantener actualizada la base de datos con la información de atletas, clubes y pruebas.

---

## 🚀 Características principales

- 📥 **Importación automática de resultados** desde un archivo CSV generado por IA.  
- 🧠 **Inserción inteligente de atletas y clubes**, evitando duplicados según edad, categoría y nombre.  
- 📊 **Gestión completa** de pruebas, atletas, clubes y resultados.  
- 🔎 **Consultas REST** para obtener resultados filtrados por atleta, club, prueba o categoría.  
- 🧩 Arquitectura basada en **Spring Boot**, con separación de capas (Controller, Service, Repository).  
- 🗃️ Soporte para **MySQL** o cualquier base de datos relacional compatible con JPA/Hibernate.

---

## 🏗️ Tecnologías utilizadas

- **Java 17+**  
- **Spring Boot 3.x**  
  - Spring Web  
  - Spring Data JPA  
  - Spring Validation  
- **MySQL** (o PostgreSQL)  
- **Lombok**  
- **Maven**  
- **OpenAPI / Swagger** para la documentación de la API  
- **Docker** (opcional)

---

## ⚙️ Estructura del proyecto

