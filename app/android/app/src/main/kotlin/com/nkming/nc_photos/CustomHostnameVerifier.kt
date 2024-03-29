package com.nkming.nc_photos

import android.content.Context
import com.nkming.nc_photos.np_android_core.logI
import java.util.Locale
import javax.net.ssl.HostnameVerifier
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLSession

class CustomHostnameVerifier(context: Context) : HostnameVerifier {
    /**
     * Allow host names allowed by user, for other hosts, revert to the default
     * behavior
     */
    override fun verify(hostname: String, session: SSLSession): Boolean {
        return if (allowedHosts.contains(hostname.lowercase(Locale.getDefault()))) {
            // good
            logI(
                "CustomHostnameVerifier::verify",
                "Allowing registered host: $hostname"
            )
            true
        } else {
            defaultHostnameVerifier.verify(hostname, session)
        }
    }

    fun reload(context: Context) {
        val certManager = SelfSignedCertManager()
        val certs = certManager.readAllCerts(context)
        allowedHosts.clear()
        for (c in certs) {
            allowedHosts.add(c.first.host.lowercase(Locale.getDefault()))
        }
    }

    private val defaultHostnameVerifier: HostnameVerifier =
        HttpsURLConnection.getDefaultHostnameVerifier()
    private val allowedHosts: MutableList<String> = ArrayList()

    init {
        reload(context)
    }
}
