[Setup]
;===========================================================
;CONFIGURAÇÕES BÁSICAS DO INSTALADOR
; Nome do aplicativo que aparecerá no instalador e no painel de controle
AppName=NomeDoSeuAplicativo  
; Versão da sua aplicação          
AppVersion=1.0     
; Caminho de instalação padrão (em Program Files 64 bits)                    
DefaultDirName={autopf64}\NomeDaPasta 
; Pasta onde o instalador final será gerado (a raiz do projeto)
OutputDir=.  
; Nome do arquivo .exe do instalador gerado                          
OutputBaseFilename=MeuAppInstaller  
; Requer privilégios de administrador para instalar   
PrivilegesRequired=admin 
; Instala como 64 bits             
ArchitecturesInstallIn64BitMode=x64   
; Permite apenas sistemas 64 bits 
ArchitecturesAllowed=x64       
; Evita instalação em caminhos de rede (UNC)        
AllowUNCPath=false               
;===========================================================

[Run]
;============================================================
; CONFIGURAÇÃO E INICIALIZAÇÃO DO SERVIÇO WINDOWS
; Usando NSSM para registrar e configurar o serviço da aplicação
;============================================================

; Cria o serviço com o nome a sua escolha ex: "seu-servico-api"
; e aponta para o executável java localizado via GetJavaHome
Filename: "{app}\nssm.exe"; Parameters: "install seu-servico-api ""{code:GetJavaHome}\bin\java.exe"""; Flags: runhidden; StatusMsg: "Registrando serviço..."

; Define os parâmetros do serviço (java -jar SeuArquivo.jar)
Filename: "{app}\nssm.exe"; Parameters: "set seu-servico-api AppParameters ""-jar """"{app}\SeuArquivo.jar.jar"""""""; Flags: runhidden

; Define o diretório onde o serviço será executado
Filename: "{app}\nssm.exe"; Parameters: "set seu-servico-api AppDirectory ""{app}"""; Flags: runhidden

; Define o nome de exibição do serviço no painel de Serviços do Windows
Filename: "{app}\nssm.exe"; Parameters: "set seu-servico-api DisplayName ""Sei Servico API"""; Flags: runhidden

; Configura o serviço para iniciar automaticamente junto com o sistema
Filename: "{app}\nssm.exe"; Parameters: "set seu-servico-api Start SERVICE_AUTO_START"; Flags: runhidden

; Define o caminho para o log da saída padrão (stdout)
Filename: "{app}\nssm.exe"; Parameters: "set seu-servico-api AppStdout ""{app}\logs\stdout.log"""; Flags: runhidden

; Define o caminho para o log de erros padrão (stderr)
Filename: "{app}\nssm.exe"; Parameters: "set seu-servico-api AppStderr ""{app}\logs\stderr.log"""; Flags: runhidden

; Inicia o serviço após o término da instalação
Filename: "{app}\nssm.exe"; Parameters: "start seu-servico-api"; Flags: runhidden; StatusMsg: "Iniciando serviço..."

[UninstallRun]
;============================================================
; ROTINA DE DESINSTALAÇÃO DO SERVIÇO
; Para e remove o serviço instalado anteriormente
;============================================================

; Para o serviço durante o processo de desinstalação
Filename: "{app}\nssm.exe"; Parameters: "stop seu-servico-api"; Flags: runhidden

; Remove o serviço permanentemente com confirmação
Filename: "{app}\nssm.exe"; Parameters: "remove seu-servico-api confirm"; Flags: runhidden

[Code]
function BoolToStr(B: Boolean): string;
begin
  if B then
    Result := 'True'
  else
    Result := 'False';
end;

var
  JavaHome: string;

function GetJavaHome(Param: string): string;
begin
  Result := JavaHome;
end;

function CheckPostgreSQLVersion14Or16Plus(): Boolean;
var
  InstallationsKey: string; SubKeys: TArrayOfString; i: Integer; FullSubKeyPath: string; VersionString: string;
begin
  Result := False;
  InstallationsKey := 'SOFTWARE\PostgreSQL\Installations';
  if RegGetSubkeyNames(HKLM, InstallationsKey, SubKeys) then
  begin
    for i := 0 to GetArrayLength(SubKeys) - 1 do
    begin
      FullSubKeyPath := InstallationsKey + '\' + SubKeys[i];
      if RegQueryStringValue(HKLM, FullSubKeyPath, 'Version', VersionString) then
      begin
        if (Copy(VersionString, 1, 3) = '14.') or (Copy(VersionString, 1, 3) = '16.') then
        begin
          Result := True; Exit;
        end;
      end;
    end;
  end;
  InstallationsKey := 'SOFTWARE\WOW6432Node\PostgreSQL\Installations';
  if not Result and RegGetSubkeyNames(HKLM, InstallationsKey, SubKeys) then
  begin
    for i := 0 to GetArrayLength(SubKeys) - 1 do
    begin
      FullSubKeyPath := InstallationsKey + '\' + SubKeys[i];
      if RegQueryStringValue(HKLM, FullSubKeyPath, 'Version', VersionString) then
      begin
        if (Copy(VersionString, 1, 3) = '14.') or (Copy(VersionString, 1, 3) = '16.') then
        begin
          Result := True; Exit;
        end;
      end;
    end;
  end;
end;

function GetJavaHomeFromRegistry(): string;
var
  JavaPath: string;
  NullPos: Integer;
begin
  Log('--- Entrando em GetJavaHomeFromRegistry ---');
  
  // Tenta ler a variável de Sistema
  if RegQueryStringValue(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 'JAVA_HOME', JavaPath) then
  begin
    Log('Valor bruto lido do registro (Sistema): "' + JavaPath + '"');
    
    // *** ETAPA DE LIMPEZA E SANITIZAÇÃO ***
    // 1. Remove qualquer coisa após um possível caractere nulo (#0)
    NullPos := Pos(#0, JavaPath);
    if NullPos > 0 then
    begin
      JavaPath := Copy(JavaPath, 1, NullPos - 1);
    end;
    // 2. Remove espaços e quebras de linha do início e do fim
    Result := Trim(JavaPath);
    // ****************************************

    Log('JAVA_HOME de Sistema (limpo e sanitizado): "' + Result + '"');
    Exit;
  end;

  // Tenta ler a variável de Usuário
  if RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'JAVA_HOME', JavaPath) then
  begin
    Log('Valor bruto lido do registro (Usuário): "' + JavaPath + '"');

    // *** ETAPA DE LIMPEZA E SANITIZAÇÃO ***
    NullPos := Pos(#0, JavaPath);
    if NullPos > 0 then
    begin
      JavaPath := Copy(JavaPath, 1, NullPos - 1);
    end;
    Result := Trim(JavaPath);
    // ****************************************

    Log('JAVA_HOME de Usuário (limpo e sanitizado): "' + Result + '"');
    Exit;
  end;

  Log('Nenhum JAVA_HOME encontrado no registro.');
  Result := '';
end;

function IsValidJavaVersion(Path: string): Boolean;
var
  ReleaseFile: string;
  FileContent: AnsiString;
begin
  Log('--- Entrando em IsValidJavaVersion (Método do arquivo "release") para o caminho: ' + Path);
  Result := False;
  ReleaseFile := Path + '\release';

  Log('Verificando a existência do arquivo: ' + ReleaseFile);
  if FileExists(ReleaseFile) then
  begin
    Log('Arquivo "release" encontrado. Lendo o conteúdo...');
    if LoadStringFromFile(ReleaseFile, FileContent) then
    begin
      Log('Conteúdo do arquivo "release": ' + #13#10 + FileContent);

      // Procura pela linha que define a versão do Java. Ex: JAVA_VERSION="17.0.15"
      // Este padrão é standard para todos os OpenJDKs modernos.
      if (Pos('JAVA_VERSION="17', FileContent) > 0) or 
         (Pos('JAVA_VERSION="18', FileContent) > 0) or 
         (Pos('JAVA_VERSION="19', FileContent) > 0) or 
         (Pos('JAVA_VERSION="2', FileContent) > 0) then // Para JDK 20, 21, etc.
      begin
        Log('Versão 17+ encontrada no arquivo "release". Versão VÁLIDA.');
        Result := True;
      end
      else
      begin
        Log('Versão 17+ NÃO encontrada no arquivo "release".');
      end;
    end
    else
    begin
      Log('Falha ao ler o conteúdo do arquivo "release".');
    end;
  end
  else
  begin
    Log('Arquivo "release" não encontrado neste caminho. Este não parece ser um JDK moderno (9+).');
  end;
  Log('--- Saindo de IsValidJavaVersion com resultado: ' + BoolToStr(Result));
end;

function CreateLogFolder(): Boolean;
var
  LogPath: string;
begin
  LogPath := ExpandConstant('{app}\logs');
  if not DirExists(LogPath) then
    Result := CreateDir(LogPath)
  else
    Result := True;
end;

// *** FUNÇÃO PRINCIPAL COM MÁXIMO DE LOGS ***
function InitializeSetup(): Boolean;
var
  JavaEnv: string;
  PostgresOK, JavaOK: Boolean;
begin
  Log('--- INICIANDO InitializeSetup (Versão de Diagnóstico Final) ---');
  
  // Passo 1: Checa o PostgreSQL
  Log('Passo 1: Verificando PostgreSQL...');
  PostgresOK := CheckPostgreSQLVersion14Or16Plus();
  if not PostgresOK then
  begin
    Log('FALHA: PostgreSQL não encontrado.');
    MsgBox('O PostgreSQL versão 14 ou 16 não foi encontrado.' + #13#10 + 'Por favor, instale-o e execute o instalador novamente.', mbError, MB_OK);
    Result := False;
    Log('--- FINALIZANDO InitializeSetup com resultado: False ---');
    Exit;
  end;
  Log('SUCESSO: PostgreSQL encontrado.');

  // Passo 2: Checa o Java
  Log('Passo 2: Verificando Java...');
  JavaEnv := GetJavaHomeFromRegistry();
  Log(Format('GetJavaHomeFromRegistry() retornou o caminho: "%s"', [JavaEnv]));

  if (JavaEnv <> '') and DirExists(JavaEnv) and IsValidJavaVersion(JavaEnv) then
  begin
    Log('SUCESSO: Todas as condições para um JDK válido foram atendidas.');
    JavaHome := JavaEnv;
    JavaOK := True;
    Result := True;
  end
  else
  begin
    Log('FALHA: Uma ou mais condições para um JDK válido falharam.');
    JavaOK := False;
    Result := False;
  end;
  
  if not JavaOK then
  begin
      MsgBox('Um JDK 17 ou superior não foi encontrado ou a variável de ambiente JAVA_HOME não está configurada corretamente.' + #13#10#13#10 + 'Por favor, instale o JDK 17 (recomendamos o Adoptium Temurin), configure a variável de ambiente JAVA_HOME e execute este instalador novamente.', mbError, MB_OK);
  end;

  // *** LINHA CORRIGIDA ***
  Log('--- FINALIZANDO InitializeSetup com resultado: ' + BoolToStr(Result));
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  LogPath: string;
begin
  if CurStep = ssPostInstall then
  begin
    LogPath := ExpandConstant('{app}\logs');
    if not DirExists(LogPath) then
    begin
      if CreateDir(LogPath) then
        Log('Pasta de logs criada com sucesso: ' + LogPath)
      else
        Log('Falha ao criar a pasta de logs: ' + LogPath);
    end
    else
      Log('A pasta de logs já existia: ' + LogPath);
  end;
end;