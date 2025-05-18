// android/build.gradle.kts (Nível do Projeto - FORA da pasta app)

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Define a versão do plugin Gradle do Android
        // Use a versão recomendada pelo seu Flutter Doctor ou uma recente compatível
        classpath("com.android.tools.build:gradle:8.2.0") // Exemplo recente

        // <<< DEFINE A VERSÃO DO KOTLIN DIRETAMENTE AQUI >>>
        // Use a versão recomendada pelo Flutter Doctor se diferente
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.20") 

        // Define o classpath do google-services (versão alinhada com app/build.gradle.kts)
        classpath("com.google.gms:google-services:4.4.2")
    }
}

// Configurações aplicadas a todos os subprojetos (app e plugins)
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configuração da pasta de build (mantendo sua configuração)
// Garante que a pasta build seja criada um nível acima da pasta android
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)
// Configura a pasta de build para cada subprojeto dentro da pasta build principal
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    // Garante que o projeto :app seja avaliado antes de outros subprojetos que possam depender dele
    project.evaluationDependsOn(":app")
}

// Tarefa personalizada para limpar a pasta de build raiz do projeto Flutter
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}