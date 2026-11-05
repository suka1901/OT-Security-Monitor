# Incidentplaybook — phishing → ransomware (fjärrvärme)


## Kill-chain (MITRE ATT&CK for ICS)
1. **Initial access** — spearphishing (T0865) → medvetenhet, e-postfiltrering, MFA
2. **Credential access** — valid accounts (T0859) → MFA, least privilege
3. **Lateral movement IT→OT** — remote services (T0886) → segmentering, zero-trust
4. **Manipulate control** — modify parameter (T0836) → avvikelsedetektion, integritetsskydd
5. **Impact** — loss of availability (T0826/T0813) → backup, IR-plan, NIS2-rapportering

## Respons (NIST CSF 2.0)
- **Detect:** korrelera IT-indikatorer (inloggningar, öst-väst-trafik, filomdöpningar) med OT-avvikelser.
- **Respond:** isolera segment, aktivera IR-plan, out-of-band-kommunikation, bevara loggar.
- **Recover:** återställ från immutabla, testade backuper; verifiera integritet innan återstart.

## NIS2 / cybersäkerhetslagen — rapporteringsklocka
- **24 h:** tidig varning till MSB
- **72 h:** incidentanmälan
- **1 månad:** slutrapport

## Förebyggande (NIST ransomware-profil)
Phishing-resistent MFA · segmentering IT/OT · allowlisting · offline/immutabla backuper · övad IR-plan · kontinuerlig övervakning.
