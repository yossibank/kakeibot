package android.database

open class SQLException
    @JvmOverloads
    constructor(
        message: String? = null,
        cause: Throwable? = null,
    ) : RuntimeException(message, cause)
