# Etapa 1: Build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build 
WORKDIR /src
# Copia el .csproj y restaura dependencias
COPY ["DockerApi.csproj" , "."]
RUN dotnet restore "DockerApi.csproj"
# Copia el resto de los archivos y compila
COPY . .
RUN dotnet build "DockerApi.csproj" -c Release -o /app/build --no-restore

# Etapa 2: Publish (Solo dependencias de produccion)
FROM build AS publish
RUN dotnet publish "DockerApi.csproj" -c Release -o /app/publish --no-restore /p:SelfContained=false /p:UseAppHost=false /p:PublishTrimmed=true /p:TrimMode=Link


# Etapa 3: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS prod
WORKDIR /app
COPY --from=publish /app/publish . 
EXPOSE 8080
ENTRYPOINT ["dotnet", "DockerApi.dll"]

####################################### EXPLICACION #####################################################

###### ETAPA BUILD ######
#FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build                     --------> Partimos del SDK completo de .NET y llamaremos build a la primera etapa
#WORKDIR /src                                                       --------> Define el directorio src, sino existe docker la crea temporalmente
#COPY["DockerApi.csproj","."]                                       --------> Copiamos el corazon de la aplicacion y la pegamos en /src
#RUN dotnet restore DockerApi.csproj                                --------> Restauramos las dependencias del corazon de la aplicacion
#COPY . .                                                           --------> Copiamos y pegamos el resto de los archivos. El origen son los archivos del mismo nivel
#                                                                         de donde se encuentra el dockerfile y los pegamos aun en /src
#RUN dotnet build "DockerApi.csproj" -c Release -o /app/build       --------> Compilamos el corazon de la aplicacion en modo release y el resultado de la compilada se guardara en /src/build
# --no-restore                                                      --------> Evita volver a descargar dependencias innecesarias.
###### ETAPA PUBLISH #######
#FROM build AS publish                                              --------> Del resultado que nos dio el stage anterior partimos y lo llamamos publish
#RUN dotnet publish "DockerApi.csproj" -c Release -o /app/publish   --------> Lo mismito que la linea anterior pero ahora lo publicamos en la carpeta publish, 
# /p:UseAppHost=false                                                         solo que el publish ya tiene una salida mas limpia con archivos requeridos
#                                                                             y la linea del /p:useApp... evita generar un ejecutable nativo (solo usa dotnet <app>.dll), lo que la hace más portable entre sistemas operativos.

###### ETAPA FINAL ########
#FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final                  --------> Ahora partimos solo de la imagen de ASP.NET core RunTime(Solo tiene lo necesario para ejecutar una aplicacion .NET)
#WORKDIR /app                                                       --------> Definimos el directorio donde vivira la app dentro del contenedor final y nos ubicamos en el.
#COPY --from=publish /app/publish .                                 --------> Aqui COPY trabaja de esta manera COPY [opciones] <origen> <destino>. En el primer param le dice a docker "El origen no esta 
#                                                                             en la computadora sino viene del stage publish". Y ahora si en origen le dice exactamente la carpeta en donde viene el origen
#                                                                             y el . final le dice que pegue todo en /app por el WORKDIR /app
#EXPOSE 8080                                                        --------> Usar siempre el puerto que use por defecto la imagen, en este caso .net usa el 8080
# ENTRYPOINT ["dotnet","DockerApi.dll"]                             --------> Define el comando por defecto que se ejecutará cuando el contenedor arranque