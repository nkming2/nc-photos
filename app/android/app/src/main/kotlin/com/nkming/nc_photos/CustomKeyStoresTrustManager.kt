package com.nkming.nc_photos

import java.security.KeyStore
import java.security.cert.CertificateException
import java.security.cert.X509Certificate
import java.util.*
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.X509TrustManager

// See: https://stackoverflow.com/a/6378872
class CustomKeyStoresTrustManager(keyStore: KeyStore) : X509TrustManager {
	/*
	 * Delegate to the default trust manager.
	 */
	@Throws(CertificateException::class)
	override fun checkClientTrusted(chain: Array<X509Certificate>,
			authType: String) {
		val defaultX509TrustManager = x509TrustManagers[0]
		defaultX509TrustManager.checkClientTrusted(chain, authType)
	}

	/*
	 * Loop over the trustmanagers until we find one that accepts our server
	 */
	@Throws(CertificateException::class)
	override fun checkServerTrusted(chain: Array<X509Certificate>,
			authType: String) {
		var defaultException: Exception? = null
		for (tm in x509TrustManagers) {
			try {
				tm.checkServerTrusted(chain, authType)
				return
			} catch (e: CertificateException) {
				// ignore
				if (defaultException == null) {
					defaultException = e
				}
			}
		}
		if (defaultException != null) {
			throw defaultException
		}
	}

	override fun getAcceptedIssuers(): Array<X509Certificate> {
		val list = ArrayList<X509Certificate>()
		for (tm in x509TrustManagers) {
			list.addAll(tm.acceptedIssuers.toList())
		}
		return list.toTypedArray()
	}

	fun setCustomKeyStore(keyStore: KeyStore) {
		val factories = ArrayList<TrustManagerFactory>()
		// The default Trustmanager with default keystore
		val original = TrustManagerFactory.getInstance(
				TrustManagerFactory.getDefaultAlgorithm())
		original.init(null as KeyStore?)
		factories.add(original)

		// with custom keystore
		val custom = TrustManagerFactory.getInstance(
				TrustManagerFactory.getDefaultAlgorithm())
		custom.init(keyStore)
		factories.add(custom)

		/*
		 * Iterate over the returned trustmanagers, and hold on
		 * to any that are X509TrustManagers
		 */
		for (tmf in factories) {
			for (tm in tmf.trustManagers) {
				if (tm is X509TrustManager) {
					x509TrustManagers.add(tm)
				}
			}
		}
		if (x509TrustManagers.isEmpty()) {
			throw RuntimeException("Couldn't find any X509TrustManagers")
		}
	}

	private val x509TrustManagers: MutableList<X509TrustManager> = ArrayList()

	init {
		setCustomKeyStore(keyStore)
	}
}
