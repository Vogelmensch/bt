#import "../definitions.typ": redbox

= Drunken Bishop

SSH is a network protocol that allows users to securely access remote computers over an unsecured network. It is based on the client-server-model and uses asymmetric cryptography methods for authentication. When a user accesses a server for the first time, the server sends a unique fingerprint, which is based on its public key. To ensure that the client is communicating with the correct server, and not with, say, an attacker, the client must make sure that they received the correct fingerprint.

A fingerprint is a string of hexadecimal numbers. In practice, remembering and comparing such a string proves to be impractical. Thus, OpenSSH 5.1 introduced a method to draw an ASCII-based image from an ssh string, images being easier to remember and compare by humans. @fingerprint_example shows an example for a fingerprint string and its ASCII-representation. The algorithm that draws the image from the fingerprint-string is called the "drunken bishop algorithm".

#figure(
  caption: "Example ssh-fingerprint as string of hexadecimal numbers (left) and as an image (right)",
  grid(
    columns: 2,
    gutter: 15pt,
    align: horizon,
    [
      `fc:94:b0:c1:e5:b0:98:7c:58:43:99:76:97:ee:9f:b7`
    ],
    [
      ```
      +-----------------+
      |       .=o.  .   |
      |     . *+*. o    |
      |      =.*..o     |
      |       o + ..    |
      |        S o.     |
      |         o  .    |
      |          .  . . |
      |              o .|
      |               E.|
      +-----------------+
      ```
    ]
  )
) <fingerprint_example>


