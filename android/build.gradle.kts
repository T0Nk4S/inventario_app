buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.3")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Asegurar que cualquier subproyecto use Java 11 como compatibilidad
// y suprimir la advertencia sobre opciones obsoletas en compilación Java.
subprojects {
    tasks.withType(org.gradle.api.tasks.compile.JavaCompile::class.java).configureEach {
        sourceCompatibility = "11"
        targetCompatibility = "11"
        // Suprimir warnings sobre opciones obsoletas (-Xlint:options)
        // y habilitar detalle de deprecations para localizarlas durante análisis
        options.compilerArgs.addAll(listOf("-Xlint:-options", "-Xlint:deprecation"))
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
