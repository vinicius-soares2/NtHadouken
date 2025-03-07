# NtHadouken - Uma viagem ao submundo do Windows Internals

<p align="center">
  <img src="https://github.com/lnt2eh/NtHadouken/blob/main/assets/NtHadouken.png" />
</p>

## 📌 Sobre o Projeto
O **NtHadouken** foi criado para orientar pesquisadores e entusiastas nos caminhos complexos do **Windows Internals**. Aqui, você encontrará papers, códigos, ferramentas e referências para aprofundar seus estudos sobre o núcleo do Windows. Espero que gostem RSRS

A curiosidade é a chama que incendeia a mente. Este projeto não é apenas sobre hacking, mas sim uma busca incansável pela maestria em **sistemas operacionais e arquitetura computacional**.

## 📖 Conteúdo

📂 **NtHadouken Papers**  
Este projeto contém uma coleção de **papers técnicos** que desenvolvemos para ajudar iniciantes e especialistas a entender melhor componentes do **Windows Internals**.

### 📜 Papers Disponíveis
- [🔹`nt!KiSystemCall64`](Papers/nt!KiSystemCall64.md)
- [🔹 KPCR (Kernel Processor Control Region)](Papers/Windows-KPCR.md)
- [🔹 Shadow Space](Papers/ShadowSpace.md) *(Em breve)*
- [🔹 TEB (Thread Environment Block)](Papers/TEB.md) *(Em breve)*
- [🔹 PEB (Process Environment Block)](Papers/PEB.md) *(Em breve)*

## 🔗 Recursos Essenciais

📚 **Artigos e Blogs**
- [Blog do Mark Russinovich](https://learn.microsoft.com/en-us/archive/blogs/markrussinovich/)
- [Matt Graeber's Blog](https://www.exploit-monday.com/)
- [James Forshaw's Blog](https://tyranidslair.blogspot.com/)
- [AdSecurity Blog](https://adsecurity.org/)
- [CERT/CC Blog](https://www.kb.cert.org/vuls/)
- [The Old New Thing](https://devblogs.microsoft.com/oldnewthing/)
- [Hexacorn](http://www.hexacorn.com/blog/)
- [Didier Stevens Labs](https://blog.didierstevens.com/)
- [Oddvar Moe Blog](https://oddvarmoe.no/)
- [Windows Kernel Explorer](https://github.com/wke/wke)

🎭 **Comunidades e Fóruns**
- [r/WindowsInternals - Subreddit](https://www.reddit.com/r/WindowsInternals/)
- [TechNet - Windows Internals Forum](https://social.technet.microsoft.com/Forums/en-US/home?forum=wininternals)
- [OSR Dev](https://www.osr.com/)
- [Windows Hacking](https://www.ired.team/)

📖 **Livros Recomendados**
- *Windows Internals, Part 1* - Pavel Yosifovich, Alex Ionescu, Mark Russinovich, David Solomon
- *Windows Internals, Part 2* - Andrea Allievi, Mark Russinovich, Alex Ionescu, David Solomon
- *Windows Kernel Programming* - Pavel Yosifovich

📑 **Referências Técnicas**
- [Microsoft Docs - Windows Internals](https://learn.microsoft.com/en-us/windows-hardware/drivers/)
- [Windows Internals Book - Official Site](https://windows-internals.com/)
- [Sysinternals Suite](https://docs.microsoft.com/en-us/sysinternals/)
- [Windows Dev Center](https://developer.microsoft.com/en-us/windows)

🛠 **Ferramentas Essenciais**
- [SysInternals](https://docs.microsoft.com/en-us/sysinternals/)
- [Windows Kernel Explorer](https://github.com/wke/wke)
- [x64dbg](https://x64dbg.com/)
- [WinDbg](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/)

## 📂 Estrutura do Projeto
```bash
NtHadouken/
│── README.md
│── assets/
│   ├── NtHadouken.png
│── Papers/
│   ├── A-Trip-to-ntKiSystemCall64.md
│   ├── KPCR.md
│   ├── ShadowSpace.md - (Скоро)
│   ├── TEB.md - (Скоро)
│   ├── PEB.md - (Скоро)
│── docs/
│   ├── index.md
│   ├── how-to-contribute.md
│── Tutorials/
│   ├──  PowerShell
│   │    ├──  CursoPowerShell.md
│   ├── Drivers/
│   │   ├── Setting-up-environment-for-creating-Windows-drivers.md
│   │   ├── (Скоро)
│   │   ├── (Скоро)
│   ├── Debugging/
│   │   ├── Set--up--KDNET-network-kernel-debugging-automatically.md
│   │   ├── Analyzing-BSOD-with-WinDBG.md
│   │   ├── Extracting-Syscalls.md - (Скоро)
│   │   ├── Debugging-Kernel-Drivers.md - (Скоро)
│   ├── Windows-Internals/
│   │   ├── Thread-Scheduling.md - (Скоро)
│   │   ├── Understanding-Paging.md - (Скоро)
│   ├── Reverse-Engineering/
│   │   ├── Reversing-NtDLL.md - (Скоро)
│   │   ├── Hooking-SSDT.md - (Скоро)
│   ├── Misc/
│   │   ├── Writing-Kernel-Exploits.md - (Скоро)
│── src/
│   ├── drivers/
│   │   ├── basic/
│   │   │   ├── HelloWorldDriver/
│   │   │   ├── SimpleDeviceDriver/ - (Скоро)
│   │   ├── security/
│   │   │   ├── KernelKeylogger/ - (Скоро)
│   │   │   ├── ProcessHider/ - (Скоро)
│   │   ├── debugging/
│   │   │   ├── KernelDebugger/ - (Скоро)
│   │   │   ├── BSODTrigger/ - (Скоро)
│   │   ├── memory/
│   │   │   ├── KernelMemoryScanner/ - (Скоро)
│   │   │   ├── VirtualMemoryMonitor/ - (Скоро)
│   ├── tools/ - (Скоро)
│── LICENSE
│── CONTRIBUTING.md
```

## 🎯 Roadmap do Projeto
- ✅ Criar e compartilhar papers técnicos sobre Windows Internals
- ✅ Disponibilizar referências de estudo para a comunidade
- ✅ Melhorar a organização e estrutura do repositório
- 🔜 Criar uma documentação interativa
- 🔜 Desenvolver ferramentas auxiliares para debugging
- 🔜 Publicar artigos no Medium e outras plataformas

## 🏴‍☠️ Filosofia do Projeto
*A chave para a liberdade está dentro de cada um de nós. Nós só precisamos ter coragem para encontrá-la.*

---

📢 **Contribua!** Se você tem interesse em Windows Internals, desenvolvimento de drivers, segurança ou engenharia reversa, este projeto é para você! 

👾 **Mantenedor:** [@lnt2Eh](https://github.com/lnt2Eh)

### Nota: O projeto está em constante evolução, então sempre irá ter novas modificações.
---
