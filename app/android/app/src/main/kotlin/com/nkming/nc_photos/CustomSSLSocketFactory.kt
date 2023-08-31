// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package com.nkming.nc_photos

import android.content.Context
import android.os.Build
import java.io.IOException
import java.net.InetAddress
import java.net.Socket
import java.security.KeyStore
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLSocket
import javax.net.ssl.SSLSocketFactory
import javax.net.ssl.TrustManager

class CustomSSLSocketFactory(context: Context) : SSLSocketFactory() {
    override fun getDefaultCipherSuites(): Array<String> {
        return sslSocketFactory.defaultCipherSuites
    }

    override fun getSupportedCipherSuites(): Array<String> {
        return sslSocketFactory.supportedCipherSuites
    }

    @Throws(IOException::class)
    override fun createSocket(): Socket {
        return enableProtocols(sslSocketFactory.createSocket())
    }

    @Throws(IOException::class)
    override fun createSocket(
        s: Socket, host: String, port: Int, autoClose: Boolean
    ): Socket {
        return enableProtocols(
            sslSocketFactory.createSocket(s, host, port, autoClose)
        )
    }

    @Throws(IOException::class)
    override fun createSocket(host: String, port: Int): Socket {
        return enableProtocols(sslSocketFactory.createSocket(host, port))
    }

    @Throws(IOException::class)
    override fun createSocket(
        host: String, port: Int, localHost: InetAddress, localPort: Int
    ): Socket {
        return enableProtocols(
            sslSocketFactory.createSocket(host, port, localHost, localPort)
        )
    }

    @Throws(IOException::class)
    override fun createSocket(host: InetAddress, port: Int): Socket {
        return enableProtocols(sslSocketFactory.createSocket(host, port))
    }

    @Throws(IOException::class)
    override fun createSocket(
        address: InetAddress,
        port: Int,
        localAddress: InetAddress,
        localPort: Int
    ): Socket {
        return enableProtocols(
            sslSocketFactory.createSocket(
                address, port, localAddress, localPort
            )
        )
    }

    fun reload(context: Context) {
        val keyStore = makeCustomKeyStore(context)
        trustManager.setCustomKeyStore(keyStore)
    }

    private fun enableProtocols(socket: Socket): Socket {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            // enable TLSv1.1 and TLSv1.2 Protocols for API level 19 and below
            if (socket is SSLSocket) {
                socket.enabledProtocols = arrayOf("TLSv1.1", "TLSv1.2")
            }
        }
        return socket
    }

    private fun makeCustomKeyStore(context: Context): KeyStore {
        // build key store with ca certificate
        val keyStoreType = KeyStore.getDefaultType()
        val keyStore = KeyStore.getInstance(keyStoreType)
        keyStore.load(null, null)

        val certManager = SelfSignedCertManager()
        val certs = certManager.readAllCerts(context)
        for (c in certs) {
            keyStore.setCertificateEntry(c.first.host, c.second)
        }
        return keyStore
    }

    private val sslSocketFactory: SSLSocketFactory
    private val trustManager: CustomKeyStoresTrustManager

    init {
        val keyStore = makeCustomKeyStore(context)
        trustManager = CustomKeyStoresTrustManager(keyStore)

        // Create an SSLContext that uses our TrustManager
        val sslContext = SSLContext.getInstance("TLS")
        sslContext.init(null, arrayOf<TrustManager>(trustManager), null)
        sslSocketFactory = sslContext.socketFactory
    }
}
