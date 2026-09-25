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

// CameraX 1.5.x exposes CallbackToFutureAdapter through this AndroidX artifact.
// Pin it on the Flutter CameraX subproject so clean builds have the classpath
// required by newer Android Gradle tooling.
subprojects {
    if (name == "camera_android_camerax") {
        configurations.configureEach {
            if (name == "implementation") {
            project.dependencies.add(
                "implementation",
                "androidx.concurrent:concurrent-futures:1.2.0",
            )
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
